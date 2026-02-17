Memo.find_or_create_by!(title: "買い物リスト") do |memo|
  memo.body = "牛乳、卵、パン、バター"
end

Memo.find_or_create_by!(title: "会議メモ") do |memo|
  memo.body = "次回のリリース日は3月1日に決定。デザインレビューは来週水曜日。"
end

Memo.find_or_create_by!(title: "読書リスト") do |memo|
  memo.body = "リファクタリング、達人プログラマー、Clean Architecture"
end
