class User < ApplicationRecord

  # association with document model
  has_many :documents, dependent: :destroy

  # Create an acessible attribute for remember token
  attr_accessor :remember_token, :activation_token, :reset_token

  # using a callback to downcase the email attribute before saving
  # needed for the data base uniqueness of email addresses
  before_save :downcase_email

  # using a callback before_create because every newly signed up user
  # will require activation - assign token and digest to user object before it's created.
  before_create :create_activation_digest


  #validates will ensure that the username is not blank
  validates :name, presence: true, length: { maximum: 50 }

  # \A = match start of a string
  # [\w+\-.]+ = at least one worc character, plus, hypen, or dot
  # @ = literal "at sign"
  # [a-z\d\-] = at least one letter, digit, or hypen
  # [a-z\d\-] = at least one letter, digit, or hyphen
  # \z = match end of string
  # / = end of regex
  # i = case-insensitive
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

  validates :email, presence: true, length: { maximum: 255 },
              format: { with: VALID_EMAIL_REGEX },
              uniqueness: { case_sensitive: false }

has_secure_password
validates :password, presence: true, length: { minimum: 8 }, allow_nil: true

# Returns the hash digest of the given string
def User.digest(string)
  cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost

  BCrypt::Password.create(string, cost: cost)
end

  # Returns true if the given token matches the digest.
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  # Returns a random token.
  def self.new_token
    SecureRandom.urlsafe_base64
  end

  # Remeber a user in the database for use in persistent sessions (cookies)
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token) )
  end

  def forget
    update_attribute(:remember_digest, nil)
  end

  # activates an account
  def activate
    update_columns(activated: true, activated_at: Time.zone.now)
  end

  # sends activation email
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  def create_reset_digest
    self.reset_token = User.new_token
    update_attribute(:reset_digest, User.digest(reset_token))
    update_attribute(:reset_sent_at, Time.zone.now)
  end

  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  def password_reset_expired?
    reset_sent_at < 1.hour.ago
  end


  private

  # Convert email address to all lower case - needed to save to db
  def downcase_email
    self.email = email.downcase
  end


  # Create and assigns the activation token and digest
  def create_activation_digest
    self.activation_token = User.new_token
    self.activation_digest = User.digest(activation_token)
  end





end
