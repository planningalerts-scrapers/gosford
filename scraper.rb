require 'mechanize'
require 'scraperwiki'

# XML feed of the applications submitted in the last month
base_url = "https://plan.gosford.nsw.gov.au/Pages/XC.Track"
url = base_url + "/SearchApplication.aspx?o=xml&d=thismonth&k=LodgementDate"

agent = Mechanize.new
page = Nokogiri::XML(agent.get(url).body)
page.search("Application").each do |app|
  record = {
    "council_reference" => app.at('ReferenceNumber').inner_text,
    "date_received" => Date.parse(app.at('LodgementDate').inner_text).to_s,
    "date_scraped" => Date.today.to_s
  }
  record["info_url"] =  base_url + "/SearchApplication.aspx?id=" + record["council_reference"]
  record["comment_url"] = base_url + "/Submission.aspx?id=" + record['council_reference']
  # Only use the first address
  record["address"] = app.at('Address Line1').inner_text + ", " + app.at('Address Line2').inner_text
  # Some DAs have good descriptions whilst others just have
  # "<insert here>" so we search for "<insert" and if it's there we
  # use another more basic description
  if app.at('ApplicationDetails').nil? || app.at('ApplicationDetails').inner_text.downcase.index(/(<|\()insert/)
    record["description"] = app.at('NatureOfApplication').inner_text
  else
    record["description"] = app.at('ApplicationDetails').inner_text
  end
  #p record
  ScraperWiki.save_sqlite(['council_reference'], record)
end
