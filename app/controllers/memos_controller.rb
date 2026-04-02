class MemosController < ApplicationController
  before_action :authenticate_user!

  def index
    @memos = Memo.default_order

    respond_to do |format|
      format.html
      format.csv do
        send_data Memo.to_csv,
                  filename: "memos-#{Date.current}.csv",
                  type: 'text/csv; charset=utf-8',
                  disposition: 'attachment'
      end
    end
  end

  def import
    file = params[:file]

    unless file.present?
      redirect_to memos_path, alert: 'ファイルを選択してください'
      return
    end

    unless file.content_type.in?(%w[text/csv application/csv application/vnd.ms-excel])
      redirect_to memos_path, alert: 'CSVファイルを選択してください'
      return
    end

    result = Memo.import(file)

    if result[:errors].empty?
      redirect_to memos_path, notice: "#{result[:imported]}件のメモをインポートしました"
    else
      error_details = result[:errors].first(5).map { |e| "行#{e[:line]}: #{e[:messages].join(', ')}" }.join('／')
      redirect_to memos_path, alert: "#{result[:imported]}件インポート、#{result[:errors].size}件エラー（#{error_details}）"
    end
  end
end
