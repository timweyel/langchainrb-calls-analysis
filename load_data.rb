require 'csv'

file_path = "calls.csv"

puts "Loading call data...\n\n"

CSV.foreach(file_path, headers: true) do |row|
  puts "Call ID: #{row['Call ID']}, Caller: #{row['Caller']}, Topic: #{row['Topic']}, Sentiment: #{row['Sentiment']}, Satisfaction: #{row['Satisfaction Score']}"
end
