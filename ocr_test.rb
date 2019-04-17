#!/usr/bin/env ruby

require 'pdf-reader'
require 'csv'

# Find PDF Inputs
pdf_files = []
csv_out = []
ARGV.each do |target|
  if File.directory?(target)
    files = Dir.glob("#{target}/**/*.pdf")
    files.each { |pdf| pdf_files << pdf }
  else
    if File.extname(target) == '.pdf'
      pdf_files << target
    end
  end
end

at_exit do
  unless csv_out.empty?
    timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
    output_csv = ENV['HOME'] + "/Desktop/ocr-scan_#{timestamp}.csv"
    CSV.open(output_csv, 'wb') do |csv|
      headers = ['Filename', 'Text']
      csv << headers
      csv_out.each { |line| csv << line }
    end
  end
end

progress_count = 1
pdf_files.each do |file|
  begin
    pdf_text = 0
    pdf_data = PDF::Reader.new(file)
    if pdf_data.page(1).text.length == 0
      pdf_data.pages.each do |page|
        pdf_text += page.text.length
      end
    else
      pdf_text += pdf_data.page(1).text.length
    end
    if pdf_text > 5
      csv_out << [file,'Text Detected']
    else
      csv_out << [file,'No Text Detected']
    end
  rescue
    csv_out << [file,'FILE SCAN ERROR']
    printf("\rChecking file %d of #{pdf_files.count}",progress_count)
    progress_count += 1
    next
  end
  printf("\rChecking file %d of #{pdf_files.count}",progress_count)
  progress_count += 1
end