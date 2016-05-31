xml.entry do
  xml.id("tag:#{request.host},#{question.resolved_at.to_date.to_s}:Question/#{question.id}")
  xml.title("type" => "html") do
    xml.text!(question.title.html_safe)
  end
  xml.link("rel" => "alternate", "href" => question_url(question))
  xml.updated(question.resolved_at.xmlschema)
  question.tags.each do |tag|
    xml.category("scheme" => root_url, "term" => tag.name)
  end
  xml.content("type" => "html") do
    xml.text!(format_text_for_display(question.body))
  end
end
