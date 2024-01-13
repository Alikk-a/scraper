class ApiChatController < ApplicationController

  def index
    message = "Who won the world series in 2020?"
    @response = ChatgptService.call(params[:message])
  end
end
