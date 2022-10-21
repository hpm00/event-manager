require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
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

def clean_phone_number(number)
  number.gsub!(/[-.()\s]/, "")
  if number.length < 10 || number.length > 11 || number.length == 11 && number[0] != "1"
    number = nil 
  elsif number.length == 11 && number[0] == "1"
    number.slice!(0)
  else 
    number
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

def open_csv
  contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
  )
end

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

open_csv.each do |row|
  id = row[0]
  
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  phone_number = clean_phone_number(row[:homephone])

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end


def freq_hour_registered
  hrs = []
  contents = open_csv
  contents.each do |row|
    hrs.push(Time.strptime(row[:regdate], '%M/%d/%y %k:%M').strftime('%H'))
  end
  new_hash = hrs.each_with_object(Hash.new(0)) {|hour, new_hash| new_hash[hour] += 1}
  hours = []
  new_hash.each{|key, value| hours.push(key.to_i) if value == new_hash.values.max}
  return hours
end

def freq_wkday_registered
  wkdays = []
  contents = open_csv
  contents.each do |row|
    wkdays.push(Time.strptime(row[:regdate], '%M/%d/%y %k:%M').strftime('%A'))
  end
  new_hash = wkdays.each_with_object(Hash.new(0)) {|wkday, new_hash| new_hash[wkday] += 1}
  new_hash.each{|key, value| return key if value == new_hash.values.max}
end 

def save_email(email)
  Dir.mkdir('email') unless Dir.exist?('email')

  filename = "email/data_analysis.html"

  File.open(filename, 'w') do |file|
    file.puts email
  end
end

template_email = File.read('email.erb')
erb_email = ERB.new template_email
email = erb_email.result(binding)
save_email(email)