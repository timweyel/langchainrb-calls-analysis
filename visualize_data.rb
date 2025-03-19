require 'csv'
require 'gruff'

# Load call data
file_path = "calls.csv"
calls = CSV.read(file_path, headers: true)

# Count sentiment distribution
sentiment_counts = Hash.new(0)
calls.each { |row| sentiment_counts[row['Sentiment']] += 1 }

# Create a bar chart with Gruff
g = Gruff::Bar.new
g.title = "Call Sentiment Distribution"
sentiment_counts.each { |sentiment, count| g.data(sentiment, [count]) }
g.labels = sentiment_counts.keys.each_with_index.to_h
g.write("sentiment_chart.png")

puts "Sentiment chart saved as sentiment_chart.png!"

# Count call topics
topic_counts = Hash.new(0)
calls.each { |row| topic_counts[row['Topic']] += 1 }

# Create a pie chart
g = Gruff::Pie.new
g.title = "Call Topics Distribution"
topic_counts.each { |topic, count| g.data(topic, count) }
g.write("call_topics_pie_chart.png")

puts "Call Topics Pie Chart saved as call_topics_pie_chart.png!"

# Group call durations into buckets
duration_ranges = { "0-5 min" => 0, "5-15 min" => 0, "15-30 min" => 0, "30+ min" => 0 }

calls.each do |row|
  duration = row["Duration (s)"].to_i
  if duration <= 300
    duration_ranges["0-5 min"] += 1
  elsif duration <= 900
    duration_ranges["5-15 min"] += 1
  elsif duration <= 1800
    duration_ranges["15-30 min"] += 1
  else
    duration_ranges["30+ min"] += 1
  end
end

# Create a bar chart
g = Gruff::Bar.new
g.title = "Call Duration Distribution"
duration_ranges.each { |range, count| g.data(range, [count]) }
g.labels = duration_ranges.keys.each_with_index.to_h
g.write("call_duration_histogram.png")

puts "Call Duration Histogram saved as call_duration_histogram.png!"

# Group satisfaction scores by date
satisfaction_trend = Hash.new { |hash, key| hash[key] = [] }
calls.each do |row|
  date = row["Timestamp"].split(" ")[0] # Extract only the date
  satisfaction_trend[date] << row["Satisfaction Score"].to_f
end

# Compute average satisfaction per day
average_satisfaction = satisfaction_trend.transform_values { |scores| scores.sum / scores.size }

# Create a line chart
g = Gruff::Line.new
g.title = "Satisfaction Score Over Time"
g.data("Avg Satisfaction", average_satisfaction.values)
g.labels = average_satisfaction.keys.each_with_index.to_h
g.write("satisfaction_trend_chart.png")

puts "Satisfaction Trend Chart saved as satisfaction_trend_chart.png!"
