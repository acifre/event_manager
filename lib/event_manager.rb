require "csv"
require "google/apis/civicinfo_v2"
require "erb"
require "time"

def open_csv_file(file_name)
  CSV.open(
    file_name,
    headers: true,
    header_converters: :symbol
  )
end
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end
def clean_phone_number(phone)
  stripped = phone.gsub(/[^0-9]/i, '')

  if stripped.length < 10 ||   stripped.length > 11
    nil
  elsif stripped.length == 11 && stripped.start_with?("1")
    stripped.sub("1", "")
  elsif stripped.length == 11 && !stripped.start_with?("1")
    nil
  else
    stripped
  end
end
def clean_time(date)
  Time.strptime(date, "%m/%d/%y %k:%M")
# m/d/yr h:m (24)
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
def save_thank_you_letter(id, form_letter)

  Dir.mkdir("output") unless Dir.exist?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename, "w") do |file|
    file.puts form_letter
  end
end
def find_peak_time(contents, date)

  time = contents.reduce({}) do |a, v|
    a[clean_time(v[date]).hour] ||= 0
    a[clean_time(v[date]).hour] += 1
    a
  end

  "Peak hour is: #{time.max_by {|k, v| v}.flatten[0]}:00."
end
def find_peak_date(contents, date)
  days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
  date = contents.reduce({}) do |a, v|
    a[clean_time(v[date]).wday] ||= 0
    a[clean_time(v[date]).wday] += 1
    a
  end

  "Peak day of the week is: #{days[date.max_by {|k, v| v}.flatten[0]]}."
end


puts "Event Manager Initialized!"

# Write Letters
template_letter = File.read("form_letter.erb")
erb_template = ERB.new template_letter
contents = open_csv_file("event_attendees.csv")
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone = clean_phone_number(row[:homephone])
  registration_time = clean_time(row[:regdate])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

end

# Find Peak Hour
times = open_csv_file("event_attendees.csv")
puts find_peak_time(times, :regdate)

# Find Peak Day of Week
dates = open_csv_file("event_attendees.csv")
puts find_peak_date(dates, :regdate)