#
require 'pathname'
require 'nokogiri'
require 'tempfile'

# Set up paths
script_path = File.dirname(__FILE__)
Target_list =  Dir.glob(script_path + '/*.xml')

#Start loop
Target_list.each do |target_file|
  target_xml = Pathname.new(target_file)
  msxsl_path = Pathname.new(script_path + '/Dependencies/msxsl.exe')
  xslfile_path = Pathname.new(script_path + '/Dependencies/at_eadToHTML.xsl')
  output_file = script_path + "/" + File.basename(target_xml,".*") + '.html'
  temp_xml_file = Tempfile.new
  temp_xml_path = Pathname.new(temp_xml_file)

  # Create tempfile and make sure EAD attributes are blank
  source_xml = File.open(target_xml)
  source_xml.each do |line|
    if line.include? '<ead '
      temp_xml_file << '<ead>'
    else
      temp_xml_file << line
    end
  end
  temp_xml_file.rewind
  # Parse EAD to make it compliant with stylesheet
  doc = Nokogiri.XML(File.open(temp_xml_file))
  ead = doc.at_css "ead"
  # Add new EAD attributes
  ead['xsi:schemaLocation'] = "urn:isbn:1-931666-22-9 http://www.loc.gov/ead/ead.xsd"
  ead['xmlns'] = "urn:isbn:1-931666-22-9"
  ead['xmlns:ns2'] = "http://www.w3.org/1999/xlink"
  ead['xmlns:xsi'] = "http://www.w3.org/2001/XMLSchema-instance"

  if ! doc.internal_subset.nil?
    doc.internal_subset.remove
  end
  # Make standard white space between title/date
  ead_date = doc.at_xpath('/ead/eadheader/filedesc/titlestmt/titleproper/date')
  ead_title = doc.at_xpath('/ead/eadheader/filedesc/titlestmt/titleproper')
  ead_date_contents = ead_date.content
  ead_title_contents = ead_title.content
  ead_date_contents.rstrip! && ead_date_contents.strip!
  ead_title_contents.rstrip! && ead_title_contents.strip!
  ead_title_contents[ead_date_contents] = " #{ead_date_contents}"
  ead_date.content = ead_date_contents
  ead_title.content = ead_title_contents
  # Remove EAD Address in favor of hard coded one in style sheet
  if doc.at_xpath('/ead/archdesc/did/repository/address')
    doc.at_xpath('/ead/archdesc/did/repository/address').remove
  end
  File.write(temp_xml_file,doc.to_xml)
  temp_xml_file.close

  #Run transform
  target_doc = Nokogiri.XML(File.open(temp_xml_file))
  template = Nokogiri.XSLT(File.open(xslfile_path))
  html_output = template.transform(target_doc)
  # Write transformed file
  File.open(output_file,'w').write(html_output)\
end