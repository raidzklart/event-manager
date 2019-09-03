require "csv"
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone(number)
  number.gsub!(/\D/, "")
  if number.length < 10
    number = "0000000000"
  elsif number.length == 11
    if number[0] == 1
      number = number[1-1]
    else
      number = "0000000000"
    end
  elsif number.length > 11
    puts number
    number = "0000000000"
  end
  number
end

def frequent_signup_hour(reg_dates)
  hours = []
  format = '%m/%d/%y %k:%M'
  reg_dates.each do |reg_date|
  date_time = DateTime.strptime(reg_date, format)
  hours << date_time.strftime("%H")
  end
  hour_freq = Hash.new(0)
  .tap { |h| hours.each { |hours| h[hours] += 1 } }
  .sort_by{ |k,v| [-v, k] }
  "#{hour_freq[0][0]}:00 is the most frequent signup hour with #{hour_freq[0][1]} signups"
end

def frequent_signup_day(reg_dates)
  weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
  days = []
  format = '%m/%d/%y %k:%M'
  reg_dates.each do |reg_date|
    date_time = DateTime.strptime(reg_date, format)
    days << date_time.wday
  end
  day_freq = Hash.new(0)
  .tap { |h| days.each { |days| h[days] += 1 } }
  .sort_by{ |k,v| [-v, k] }
  "#{weekdays[day_freq[0][0]]} is the most frequent signup day with #{day_freq[0][1]} signups"
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
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letters(id,form_letter)
  Dir.mkdir("output") unless Dir.exists?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename,'w') do |file|
    file.puts form_letter
  end
end

puts "\n\nEventManager Initialized!\n\n"

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol
reg_dates = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone = clean_phone(row[:homephone])
  reg_dates << row[:regdate]
  # legislators = legislators_by_zipcode(zipcode)

  # form_letter = erb_template.result(binding)
  # Dir.mkdir("output") unless Dir.exists? "output"

  # filename = "output/thanks_#{id}.html"

  # save_thank_you_letters(id,form_letter)
end

puts frequent_signup_hour(reg_dates)
puts frequent_signup_day(reg_dates)
