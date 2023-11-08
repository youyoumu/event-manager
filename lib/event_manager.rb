require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

def clean_phone_number(number)
  clean_number = ''
  number.each_char do |char|
    clean_number << char if "0123456789".include?(char)
  end
  return nil if clean_number.length < 10
  return clean_number if clean_number.length == 10
  if clean_number.length == 11 && clean_number[0] == "1"
    clean_number.slice!(0)
    return clean_number
  else
    return nil
  end
  return nil if clean_number.length > 11
end

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  number = row[5]
  puts "#{number} #{clean_phone_number(number)}"
end

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

hour_counts = Hash.new(0)
weekday_count_raw = Hash.new(0)
contents.each do |row|
  time = row[1]
  parsed_time = Time.strptime(time, "%m/%d/%y %H:%M")
  hour = parsed_time.hour
  hour_counts[hour] += 1

  weekday = parsed_time.wday
  weekday_count_raw[weekday] += 1
end
puts hour_counts

weekday_count = {}
weekday_count_raw.each do |key, value|
  case key
  when 0
    weekday_count["Sunday"] = value
  when 1
    weekday_count["Monday"] = value
  when 2
    weekday_count["Tuesday"] = value
  when 3
    weekday_count["Wednesday"] = value
  when 4
    weekday_count["Thursday"] = value
  when 5
    weekday_count["Friday"] = value
  when 6
    weekday_count["Saturday"] = value
  end
end

puts weekday_count
