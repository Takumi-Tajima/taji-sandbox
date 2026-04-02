require 'csv'

class Memo < ApplicationRecord
  validates :title, presence: true
  validates :body, presence: true

  scope :default_order, -> { order(:id) }

  CSV_HEADERS = %w[id title body created_at].freeze

  def self.to_csv
    CSV.generate(headers: true) do |csv|
      csv << CSV_HEADERS
      find_each do |memo|
        csv << CSV_HEADERS.map { |attr| memo.public_send(attr) }
      end
    end
  end

  def self.import(file)
    imported = 0
    errors = []

    CSV.foreach(file.path, headers: true, liberal_parsing: true).with_index(2) do |row, line_num|
      memo = new(title: row['title']&.strip, body: row['body']&.strip)
      if memo.save
        imported += 1
      else
        errors << { line: line_num, messages: memo.errors.full_messages }
      end
    end

    { imported: imported, errors: errors }
  end
end
