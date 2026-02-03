require 'sinatra'
require 'json'
require 'random/formatter'
require 'uuid'
require 'base64'

=begin

For our rest service that supports Q&A we will set up these route schemes:

- Create questions ***
  - define model ***
  - data validation ***
- Get all questions ***
- Check authorization ***
- Filter questions ***
- Get a question ***
- Answer a question ***
  - define model ****
  - data validation ****
- Get all question answers ***
- Get a questions and all of it's answers ***
- Delete question ***
- Delete answer ***
- Filter all question answers ***
- Edit question
  - data validation
- Edit answer
  - data validation


=end

=begin

  status options: [answered, unanswered]

  QUESTIONS
  id: UUID ~ auto generated
  title: string
  description: string
  status: string
  authorId: UUID of an author (arbitrary string for example)
  createdAt: number
  createdById: UUID
  updatedAt: number
  updatedById: UUID
  deletedAt: number?
  deletedById: UUID?
  

  ANSWERS
  id: UUID ag
  questionId: uuid 
  answer: string 
  authorId: UUID of an author (arbitrary string for example)
  createdAt: number
  createdById: UUID
  updatedAt: number
  updatedById: UUID
  deletedAt: number?
  deletedById: UUID?

=end

questionsArray = []
questionsHash = {}

answersArray = []
answersHash = {}

questionsAnswersHash = {}

user = {}

def authorize(request)
  token = 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4MzkyMmJiOS1jMTg0LTQ2NzEtODkxZC0yMzA2NmMzNzkzZWMiLCJuYW1lIjoiSm9obiBEb2UiLCJhZG1pbiI6dHJ1ZSwiaWF0IjoxNTE2MjM5MDIyfQ==.KMUFsIDTnFmyG3nMiGM6H9FNFUROf3wh7SmqJp-QV30'
  
  return false unless request.has_header?('HTTP_AUTHORIZATION') && request.fetch_header('HTTP_AUTHORIZATION') == token

  tokenSplit = token.split('.')[1]

  fixedUser = {}
  JSON.parse(Base64.decode64(tokenSplit)).each_pair do |k, v|
   fixedUser[k.to_sym] =  v
  end

  fixedUser
end


## ------------------------------------------------------------------------------------------- POST

post '/questions' do
  user = authorize(request)
  unless user
    status 401
    return "Unauthorized"
  end

  authorId = user[:sub]

  requiredKeys = ['title', 'description']

  request.body.rewind  # in case someone already read it
  questionBodyCheck = request.body.read 
  
  if questionBodyCheck.empty?
    status 400
    return "Invalid payload."
  end

  questionBody = JSON.parse questionBodyCheck

  #data validation
  unless questionBody.keys.difference(requiredKeys).empty?
    status 400
    return "Invalid payload."
  end

  requiredKeys.each do |key|
    unless questionBody.has_key?(key) && questionBody[key].strip != ""
      status 400
      return "Invalid request, missing key: #{key}."
    end
  end

  unless UUID.validate(authorId)
    status 400
    return "Invalid authorId."
  end
  #end data validation

  now = Time.now.to_i

  question = {}
  questionBody.each_key do |key|
      question[key.to_sym] = questionBody[key]
  end

  question[:id] = UUID.generate
  question[:status] = 'unanswered'
  question[:authorId] = authorId
  question[:createdAt] = now
  question[:createdById] = authorId
  question[:updatedAt] = now
  question[:updatedById] = authorId
  question[:deletedAt] = nil
  question[:deletedById] = nil

  questionsArray << question
  questionsHash[question[:id].to_sym] = question

  JSON.dump(question)
end

# id: UUID ag
# questionId: uuid *
# answer: string *
# authorId: UUID of an author (arbitrary string for example) *
# createdAt: number
# createdById: UUID
# updatedAt: number
# updatedById: UUID
# deletedAt: number?
# deletedById: UUID?



post '/questions/:id/answers' do |id|
  user = authorize(request)
  unless user
    status 401
    return "Unauthorized"
  end

  authorId = user[:sub]

  # checks request body and verifies NOT empty - = answer body
  request.body.rewind
  answerBodyCheck = request.body.read 

  requiredKeys = ['answer']

  if answerBodyCheck.empty?
    status 400
    return "Invalid payload."
  end

  answerBody = JSON.parse answerBodyCheck

  #validation
  unless UUID.validate(id)
    status 400
    return "Invalid question id"
  end

  unless questionsHash.has_key?(id.to_sym) && !questionsHash[id.to_sym][:deletedAt]
    status 400
    return "Invalid question id"
  end

  unless answerBody.keys.difference(requiredKeys).empty?
    status 400
    return "Invalid payload."
  end

  requiredKeys.each do |key|
    unless answerBody.has_key?(key) && answerBody[key].strip != ""
      status 400
      return "Invalid request, missing key: #{key}."
    end
  end

  unless UUID.validate(authorId)
    status 400
    return "Invalid author id"
  end
  #end validation  

  answer = {}
  answerBody.each_key do |key|
      answer[key.to_sym] = answerBody[key]
  end

  now = Time.now.to_i

  answer[:id] = UUID.generate
  answer[:questionId] = id.to_sym
  answer[:authorId] = authorId
  answer[:createdAt] = now
  answer[:createdById] = authorId
  answer[:updatedAt] = now
  answer[:updatedById] = authorId
  answer[:deletedAt] = nil
  answer[:deletedById] = nil

  answersArray << answer
  answersHash[answer[:id].to_sym] = answer
  unless questionsAnswersHash[id.to_sym]
    questionsAnswersHash[id.to_sym] = [answer]
  else
    questionsAnswersHash[id.to_sym] << answer
  end

  questionsHash[id.to_sym][:status] = 'answered'

  JSON.dump(answer)  
end

## ------------------------------------------------------------------------------------------- PUT
#this is going to be an upsert style - edit a question

## TESTS
# new question + pat - ok
# new question invalid id (new question post) - ok 
# same info as an existing question - ok
# CHECK NOTES ON PATCH CHECK -- NOT ALL THE KEYS WILL NECESSARILY BE THERE...


put '/questions' do 
  user = authorize(request)
  unless user
    status 401
    return "Unauthorized"
  end

  postCheck = false
  payloadOptions = ['title', 'description']

  request.body.rewind  # in case someone already read it
  questionBodyCheck = request.body.read 

  puts "testing first validate"
  if questionBodyCheck.empty?
    status 400
    return "Invalid payload."
  end

  questionBody = JSON.parse questionBodyCheck
  qId = questionBody['id']
  oldQ = questionsHash[qId.to_sym] # this is not grabbing anything - will need to inspect the questions hash next time
  #TODO: ^^

  3.times {puts '-'}
  puts "checking qId & oldQ"
  p qId
  puts ""
  p oldQ
  3.times {puts '*'}
  
  # this section confirms the id in the body - a valid id will mean that we need to update IF there is a difference in values
  # otherwise we need to post 

  if qId && !qId.strip.empty? && UUID.validate(qId.to_sym) # question id in body and with valid format: -- MAKE THIS A SYMBOL in the above def and then go through all the calls
    if questionsHash[qId.to_sym] # question id matches an existing question in our question hash
      postCheck = false
      questionExists = true # we need to now check diffs 
    else
      # question id IS in body but doesn't match an existing question - which should never happen
      status 400
      return "Invalid question id"
    end
  else
    questionExists = false 
  end

  if questionExists
    oldOptions = [oldQ[:title], oldQ[:description]]
    newOptions = [questionBody[:title], questionBody[:description]] #THIS SHOULD BE QUESTION BODY INSTEAD OF QID (qid is just the id of question body)
    if newOptions.difference(oldOptions).empty? # attempts to check differences between the passed in title and description against the existing question.
      status 202
      return "There were no updates made to the existing entry."
    else
      #needs to update 
      postCheck = true # will do the put / patch after validations
    end
  else
    postCheck = true
  end

  #--------------------#
  requiredKeys = ['title', 'description']
  #--------------------#

  # THIS IS THE PATCH - ALLOWS FOR EMPTY KEYS IF EXISTING QUESTION ALREADY HAS THE INFO
  if questionExists && postCheck
    # copy over the existing fields if the questionBody doesn't have them

    authorId = user[:sub]
    now = Time.now

    question = {}
    questionBody.each_key do |key|
      next if key == :id || key == 'id' #already exists 
      question[key.to_sym] = questionBody[key]
    end

    puts "second test"
    p question.keys
    p requiredKeys.map{|key| key.to_sym}
    #CHANGE THIS TO COMPARE EXISTING WITH GIVEN AND USE EXISTING IF GIVEN IS INVALID - Q ALREADY EXISTS
    unless question.keys.difference(requiredKeys.map{|key| key.to_sym}).empty?
      status 400
      return "Invalid payload."
    end

    # in real world - key might not be present if only one thing was updated... so remove this section
    requiredKeys.each do |key|
      unless questionBody.has_key?(key) && questionBody[key].strip != ""
        status 400
        return "Invalid request, missing key: #{key}."
      end
    end


    #this also won't work because we may not get all the keys in question body - instead look through all the question body keys con compare
    requiredKeys.each do |key|
      if questionBody.has_key?(key) && ( questionBody[key].strip == "" || questionBody[key].nil? )
        if oldQ[key]
          questionBody[key] = oldQ[key]
        else
          status 400
          return "Invalid request, missing key: #{key}."
        end
      end
    end
    
    oldQ[:title] = questionBody['title']
    oldQ[:description] = questionBody['description']
    oldQ[:updatedAt] = now
    oldQ[:updatedById] = authorId


    puts ""
    p oldQ
    return JSON.dump(oldQ)
  end

  # BASICALLY THE POST ABOVE - REQUIRES ALL KEYS TO BE IN QUESTION BODY
  if !questionExists && postCheck
    puts "INSIDE OTHER IF STATEMENT"
    authorId = user[:sub] #only use this one - just move it to the use area | confusing name

    requiredKeys = ['title', 'description']

    puts "3rd test"
    #data validation
    updatedQuestionBody = []
    questionBody.keys.each {|key| updatedQuestionBody << key unless key == 'id'}
    unless updatedQuestionBody.difference(requiredKeys).empty?
      status 400
      return "Invalid payload."
    end

    requiredKeys.each do |key|
      unless questionBody.has_key?(key) && questionBody[key].strip != ""
        status 400
        return "Invalid request, missing key: #{key}."
      end
    end

    unless UUID.validate(authorId)
      status 400
      return "Invalid authorId."
    end
    #end data validation

    now = Time.now.to_i

    question = {}
    questionBody.each_key do |key|
      question[key.to_sym] = questionBody[key]
    end

    question[:id] = UUID.generate
    question[:status] = 'unanswered'
    question[:authorId] = authorId
    question[:createdAt] = now
    question[:createdById] = authorId
    question[:updatedAt] = now
    question[:updatedById] = authorId
    question[:deletedAt] = nil
    question[:deletedById] = nil

    questionsArray << question
    questionsHash[question[:id].to_sym] = question

    return JSON.dump(question)
  end

end


put '/answers' do
  ser = authorize(request)
  unless user
    status 401
    return "Unauthorized"
  end

  postCheck = false
  payloadOptions = ['title', 'description']

  request.body.rewind  # in case someone already read it
  answerBodyCheck = request.body.read 

  puts "testing first validate"
  if answerBodyCheck.empty?
    status 400
    return "Invalid payload."
  end

  answerBody = JSON.parse answerBodyCheck

  ##if answer body has a valid id, do a patch, otherwise to a post 



  aId = answerBody['id']
  oldA = answersHash[aId.to_sym] 


end



## ------------------------------------------------------------------------------------------- GET

get '/questions' do
  user = authorize(request)
  unless user
    status 401
    return "Unauthorized"
  end

  queryKeys = ['id', 'title', 'description', 'authorId', 'createdById', 'updatedById']

  hasFilter = queryKeys.reduce(false) do |accumulator, value|
    accumulator || (params.has_key?(value) && !params[value].empty?)
  end

  validQuestions = questionsArray.select {|question| !question[:deletedAt]}

  return JSON.dump(validQuestions) unless hasFilter
  

  filteredQuestions = validQuestions.select do |question|
    queryKeys.reduce(false) do |accumulator, key|
      accumulator || params.has_key?(key) && !params[key].empty? && question[key.to_sym].strip.include?(params[key].strip)
    end
  end

  JSON.dump(filteredQuestions)
end



get '/questions/:id' do |id|
  user = authorize(request)
  unless user
    status 401
    return "Unauthorized"
  end
  
  # validation
  unless id && !id.strip.empty? && UUID.validate(id)
    status 400
    return "Invalid question id."
  end

  unless questionsHash[id.to_sym] && !questionsHash[id.to_sym][:deletedAt]
    return nil
  end
  # end validation

  JSON.dump(questionsHash[id.to_sym])
end



# id: UUID ag
# questionId: uuid *
# answer: string *
# authorId: UUID of an author (arbitrary string for example) *
# createdAt: number
# createdById: UUID
# updatedAt: number
# updatedById: UUID
# deletedAt: number?
# deletedById: UUID?



get '/questions/:id/answers' do |id|
  user = authorize(request)
  unless user
    status 401
    return "Unauthorized"
  end

  #validations
  unless id && !id.strip.empty? && UUID.validate(id)
    status 400
    return "Invalid question id."
  end
  #end validations

  return JSON.dump([]) if questionsHash[id.to_sym] && questionsHash[id.to_sym][:deletedAt]

  activeAnswers = (questionsAnswersHash[id.to_sym] && questionsAnswersHash[id.to_sym].select {|a| !a[:deletedAt]}) || []

  ## FILTER SECTION
          #change id to answerId

  
  queryKeys = ['answerId', 'questionId', 'answer', 'authorId', 'createdById', 'updatedById']

  hasFilter = queryKeys.reduce(false) do |accumulator, value|
                    #this is always true in id
    accumulator || (params.has_key?(value) && !params[value].empty?)
  end

  p hasFilter
  return JSON.dump(activeAnswers) unless hasFilter

  mapper = {}
  mapper[:answerId] = {params: :answerId, object: :id}
  mapper[:questionId] = {params: :questionId, object: :questionId}
  mapper[:answer] = {params: :answer, object: :answer}
  mapper[:authorId] = {params: :authorId, object: :authorId}
  mapper[:createdById] = {params: :createdById, object: :createdById}
  mapper[:updatedById] = {params: :updatedById, object: :updatedById}


  filteredAnswers = activeAnswers.select do |answer|
    queryKeys.reduce(false) do |accumulator, key|
      paramsKey = mapper[key.to_sym][:params].to_s
      objectKey = mapper[key.to_sym][:object]

      # seems like key is actually passing value when ?answerId=xxxx...
      accumulator || params.has_key?(paramsKey) && !params[paramsKey].empty? && answer[objectKey].strip.include?(params[paramsKey].strip)
    end
  end
  puts "filterd"
  p filteredAnswers
 ## END FILTER

  JSON.dump(filteredAnswers) 
end


get '/questions/:id/qna' do |id|
  user = authorize(request)
  unless user
    status 401
    return "Unauthorized"
  end

  # validations
  unless id && !id.strip.empty? && UUID.validate(id)
    status 400
    return "Invalid question id."
  end 
  # end validations

  return JSON.dump(nil) unless questionsHash[id.to_sym] && !questionsHash[id.to_sym][:deletedAt]
  question = questionsHash[id.to_sym].dup 

  question[:answers] = (questionsAnswersHash[id.to_sym] && questionsAnswersHash[id.to_sym].select {|a| !a[:deletedAt]}) || []

  JSON.dump(question)
end

## ------------------------------------------------------------------------------------------- DELETE

delete '/questions/:id' do |id|
  user = authorize(request)
  unless user
    status 401
    return "Unauthorized"
  end

  deletedById = user[:sub]

  question = questionsHash[id.to_sym]

  #validations
  unless id && !id.strip.empty? && UUID.validate(id)
    status 400
    return "Invalid question id."
  end 

  unless question
    status 400
    return "No question with id exists"
  end

  unless UUID.validate(deletedById)
    status 400
    return "Invalid deleted by id"
  end
  #end validations

  return JSON.dump(question) if question[:deletedAt]
  
  now = Time.now

  question[:deletedAt] = now
  question[:deletedById] = deletedById
  question[:updatedAt] = now
  question[:updatedById] = deletedById

  return JSON.dump(question) unless questionsAnswersHash[id.to_sym]

  questionsAnswersHash[id.to_sym].each do |answer|
    answer[:deletedById] = deletedById
    answer[:deletedAt] = now
    answer[:updatedAt] = now
    answer[:updatedById] = deletedById
    puts "answer deleted"
  end

  JSON.dump(question)
end



delete '/questions/:id/answers/:aid' do |id, aid|
  user = authorize(request)
  unless user
    status 401
    return "Unauthorized"
  end

  deletedById = user[:sub]
  answer = answersHash[aid.to_sym]

  #validations
   
  unless id && !id.strip.empty? && UUID.validate(id)
    status 400
    return "Invalid question id."
  end 
  
  unless aid && !aid.strip.empty? && UUID.validate(aid)
    status 400
    return "Invalid answer id."
  end 

  unless answer[:questionId] == id.to_sym
    status 400
    return 'Answer does not belong to given question.'
  end
  
  #end validations

  return JSON.dump(answer) if answer[:deletedAt]

  now = Time.now

  answer[:deletedAt] = now
  answer[:deletedById] = deletedById
  answer[:updatedAt] = now
  answer[:updatedById] = deletedById

  return JSON.dump(answer)

end


