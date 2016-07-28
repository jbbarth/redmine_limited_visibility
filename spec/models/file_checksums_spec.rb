require File.dirname(__FILE__) + '/../spec_helper'

describe "FileChecksums" do
  def assert_checksum(expected, filename)
    filepath = Rails.root.join(filename)
    checksum = Digest::MD5.hexdigest(File.read(filepath))
    assert checksum.in?(Array(expected)), "Bad checksum for file: #{filename}, local version should be reviewed: checksum=#{checksum}, expected=#{Array(expected).join(" or ")}"
  end

  it "should core blocks checksums" do
    # tbody in index view is overridden and should be reviewed each time it changes (copy/paste from core file in override)
    assert_checksum %w(c41a00ab7905f8a76af5471aebcc702b b5709933b0adc728ca69ebe90b4cb9ea), "app/views/roles/index.html.erb"
  end

end
