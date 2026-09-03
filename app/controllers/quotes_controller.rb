class QuotesController < ApplicationController
  def random
    @quote = Quote.random
  end
end
