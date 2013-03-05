xml.entry do
  xml.id("tag:#{request.host},#{question.resolved_at.to_date.to_s}:Question/#{question.id}")
  xml.title("type" => "html") do
    xml.text!(format_text_for_display(question.title))
  end
  xml.link("rel" => "alternate", "href" => question_url(question))
  xml.updated(question.resolved_at.xmlschema)
  xml.content("type" => "html") do
    xml.text!(format_text_for_display(question.body))
  end
end
