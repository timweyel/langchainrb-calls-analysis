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

# Count topic frequencies to find the top 3
topic_counts = Hash.new(0)
calls.each { |row| topic_counts[row["Topic"]] += 1 }
top_topics = topic_counts.sort_by { |_, count| -count }.first(3).map(&:first)

# Organize sentiment scores by topic and date
topic_sentiment_trends = Hash.new { |hash, key| hash[key] = Hash.new { |h, k| h[k] = [] } }

calls.each do |row|
  date = row["Timestamp"].split(" ")[0] # Extract date (YYYY-MM-DD)
  topic = row["Topic"]
  sentiment_score = row["Satisfaction Score"].to_f

  # Only keep top 3 topics
  next unless top_topics.include?(topic)

  topic_sentiment_trends[topic][date] << sentiment_score
end

# Compute average sentiment per topic per day
average_sentiment_by_topic = {}
topic_sentiment_trends.each do |topic, date_scores|
  daily_avg = date_scores.transform_values { |scores| scores.sum / scores.size }

  # Apply rolling average smoothing
  dates = daily_avg.keys.sort
  smoothed_scores = []
  dates.each_with_index do |date, i|
    window = dates[[0, i - 1].max..i] # 3-day rolling average
    smoothed_scores << (window.map { |d| daily_avg[d] }.sum / window.size)
  end

  average_sentiment_by_topic[topic] = smoothed_scores
end

# Create a line chart for sentiment trends per topic
g = Gruff::Line.new
g.title = "Smoothed Sentiment Trends for Top 3 Topics"

average_sentiment_by_topic.each do |topic, trend|
  g.data(topic, trend)
end

# Improve date labels (show every 10th day and rotate them)
all_dates = topic_sentiment_trends.values.flat_map(&:keys).uniq.sort
selected_dates = all_dates.each_with_index.select { |_, i| i % 10 == 0 }.map(&:first)
g.labels = selected_dates.each_with_index.to_h { |date, i| [i * 10, date] }  # Ensure spacing
g.marker_font_size = 10  # Make the labels smaller for better readability
g.x_axis_label = "Date"  # Label the x-axis
g.y_axis_label = "Sentiment Score"  # Label the y-axis

g.write("cleaned_sentiment_trends.png")

puts "Cleaned Sentiment Trends Chart saved as cleaned_sentiment_trends.png!"
