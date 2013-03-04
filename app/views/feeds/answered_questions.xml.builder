xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
  xml.id("tag:#{request.host},2005:Ask_an_Expert_Public_Resolved_Questions_Feed/#{request.path}")
  xml.title("eXtension Ask an Expert Resolved Public Questions")
  xml.link("rel" => "alternate", "href" => root_url)
  xml.link("rel" => "self", "href" => request.url)
  xml.updated((@questions.first.resolved_at + 1).xmlschema)
  xml.author do
    xml.name("eXtension Ask an Expert")
  end
  @questions.each do |question|
    xml << render(:partial => 'question', :locals => {:question => question})
  end
end
