class MemosController < ApplicationController
  before_action :authenticate_user!

  def index
    @memos = Memo.default_order
  end
end
