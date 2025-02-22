require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phonenumber(phone)
  phone_arr = phone.split('').select { |number| number >= '0' && number <= '9' }
  phone_cleaned = phone_arr.join
  if phone_cleaned.length < 10 || phone_cleaned.length > 11 || (phone_cleaned.length == 11 && phone_cleaned[0] != '1')
    phone_cleaned = 'invalid HomePhone'
  elsif phone_cleaned.length == 11
    phone_cleaned.slice!(1)
  end
  phone_cleaned
end

def get_hour(datetime, time_hash)
  time_hash[Time.strptime(datetime, "%m/%d/%Y %k:%M").hour] += 1
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = File.read('secret.key').strip

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

def get_most_hour(time_hash)
  max_val = time_hash.values.max
  p time_hash.select { |key, value| value ==  max_val }
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
time_hash = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone = clean_phonenumber(row[:homephone])
  get_hour(row[:regdate], time_hash)
  # zipcode = clean_zipcode(row[:zipcode])

  # legislators = legislators_by_zipcode(zipcode)
  
  # form_letter = erb_template.result(binding)

  # save_thank_you_letter(id,form_letter)
end

get_most_hour(time_hash)
