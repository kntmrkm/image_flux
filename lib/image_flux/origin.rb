# frozen_string_literal: true

require 'uri'
require 'openssl'
require 'base64'
require 'image_flux'

class ImageFlux::Origin
  attr_reader :domain, :scheme, :signing_version, :signing_secret
  def initialize(domain:, scheme: 'https', signing_version: '1', signing_secret: nil, **_options)
    @domain = domain.to_s
    @scheme = scheme.to_s
    @signing_version = signing_version
    @signing_secret = signing_secret
  end

  def base_url
    @base_url ||= URI("#{@scheme}://#{@domain}/")
  end

  def image_url(path, options = {})
    path = "/#{path}" unless path.start_with?('/')

    options = options.merge(sig: sign(path)) if @signing_secret
    opt = ImageFlux::Option.new(options)

    path = "#{opt.prefix_path}#{path}" if opt.prefix_path
    query = opt.to_query

    url = base_url.dup
    url.path = query.length.zero? ? path : "/c/#{opt.to_query}#{path}"

    url
  end

  def sign(path)
    digest = OpenSSL::HMAC.digest('sha256', @signing_secret, path)

    "#{@signing_version}.#{Base64.urlsafe_encode64(digest)}"
  end
end
