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
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone = clean_phone(row[:homephone])
  puts phone
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  # Dir.mkdir("output") unless Dir.exists? "output"

  # filename = "output/thanks_#{id}.html"

  # save_thank_you_letters(id,form_letter)
end
