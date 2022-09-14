module SharedVariables
  @public_token = "INSERT_TRIPLESEAT_TOKEN"
  @secret_key = "INSERT_TRIPLESEAT_TOKEN"

  def self.public_token
    return @public_token
  end

  def self.secret_key
    return @secret_key;
  end
end
