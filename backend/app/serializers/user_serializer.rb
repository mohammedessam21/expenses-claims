module UserSerializer
  def self.call(user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      company: { id: user.company.id, name: user.company.name }
    }
  end
end
