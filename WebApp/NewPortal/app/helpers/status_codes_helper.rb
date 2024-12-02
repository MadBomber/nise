module StatusCodesHelper

=begin
    <td align="center">
      <% status_code = StatusCode.find_by_code(dispatcher.status) %>
      <%= link_to dispatcher.status, status_code, :title => status_code.description %>
    </td>
=end

  def link_to_status_code(a_code)
  
    status_code = StatusCode.find_by_code(a_code)
    link_to(a_code, status_code, :title => status_code.description)
  
  end

end
