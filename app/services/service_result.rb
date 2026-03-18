class ServiceResult
  attr_reader :error, :message

  def self.ok(**data)
    new(success: true, **data)
  end

  def self.err(error:, message:, **data)
    new(success: false, error: error, message: message, **data)
  end

  def initialize(success:, error: nil, message: nil, **data)
    @success = success
    @error   = error
    @message = message
    @data    = data
  end

  def success?
    @success
  end

  def [](key)
    case key
    when :success then @success
    when :error   then @error
    when :message then @message
    else @data[key]
    end
  end
end
