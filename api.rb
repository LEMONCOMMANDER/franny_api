require 'sinatra'
require 'json'
require 'random/formatter'
require 'uuid'

=begin

For our rest service that supports Q&A we will set up these route schemes:

- Create questions ***
  - define model ***
  - data validation ***
- Get all questions ***
- Check authorization ***
- Filter questions ***
- Get a question ***
- Answer a question
  - define model
  - data validation
- Get all question answers
- Filter all question answers
- Edit question
  - data validation
- Edit answer
  - data validation
- Delete question
- Delete answer

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

def authorize(request)
  request.has_header?('HTTP_AUTHORIZATION') && request.fetch_header('HTTP_AUTHORIZATION') == 'Bearer TOKEN-HERE'
end

## POST

post '/questions' do
  unless authorize(request)
    status 401
    return "Unauthorized"
  end


  requiredKeys = ['title', 'description', 'authorId']

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

  unless UUID.validate(questionBody['authorId'])
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
  question[:createdAt] = now
  question[:createdById] = questionBody['authorId']
  question[:updatedAt] = now
  question[:updatedById] = questionBody['authorId']
  question[:deletedAt] = nil
  question[:deletedById] = nil

  questionsArray << question
  questionsHash[question[:id].to_sym] = question

  JSON.dump(question)
end

# id: UUID ag
# questionId: uuid 
# answer: string 
# authorId: UUID of an author (arbitrary string for example)
# createdAt: number
# createdById: UUID
# updatedAt: number
# updatedById: UUID
# deletedAt: number?
# deletedById: UUID?


post '/questions/:id/answers' do |id|
  unless authorize(request)
    status 401
    return "Unauthorized"
  end

  #validation
    
  #end validation  



  JSON.dump(answer)  
end


## GET

get '/questions' do
  unless authorize(request)
    status 401
    return "Unauthorized"
  end

  queryKeys = ['id', 'title', 'description', 'authorId', 'createdById', 'updatedById', 'deletedById']

  hasFilter = queryKeys.reduce(false) do |accumulator, value|
    accumulator || (params.has_key?(value) && !params[value].empty?)
  end

  return JSON.dump(questionsArray) unless hasFilter
  

  filteredQuestions = questionsArray.select do |question|
    queryKeys.reduce(false) do |accumulator, key|
      accumulator || params.has_key?(key) && !params[key].empty? && question[key.to_sym].strip.include?(params[key].strip)
    end
  end

  JSON.dump(filteredQuestions)
end

get '/questions/:id' do |id|
  unless authorize(request)
    status 401
    return "Unauthorized"
  end
  
  # validation
  unless id && !id.strip.empty? && UUID.validate(id)
    status 400
    return "Invalid question id."
  end
  # end validation

  JSON.dump(questionsHash[id.to_sym])
end