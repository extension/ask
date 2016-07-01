class AdminConstraint
  def matches?(request)
    return false unless request.session["warden.user.user.key"]
    user = User.find(request.session["warden.user.user.key"][1][0])
    user && user.signin_allowed? && user.is_admin?
  end
end
