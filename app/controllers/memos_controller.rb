class MemosController < ApplicationController
  def index
    @memos = Memo.order(created_at: :desc)
  end
end
