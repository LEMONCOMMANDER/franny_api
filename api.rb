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
- Delete question
- Delete answer
- Filter all question answers
- Edit question
  - data validation
- Edit answer
  - data validation


=end

=begin

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

## POST

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

  puts "USER"
  p user

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


## GET

get '/questions' do
  user = authorize(request)
  unless user
    status 401
    return "Unauthorized"
  end

  queryKeys = ['id', 'title', 'description', 'authorId', 'createdById', 'updatedById', 'deletedById']

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

  JSON.dump(questionsAnswersHash[id.to_sym] || [])
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

## DELETE

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

  ## get this validated - only do if question has answers
  questionsAnswersHash[id.to_sym].each do |answer|
    answer[:deletedAt] = now
    answer[:deletedById] = authorId
    puts "answer deleted"
  end

  JSON.dump(question)
end