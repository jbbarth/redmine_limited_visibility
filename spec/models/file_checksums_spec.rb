require 'spec_helper'

describe "FileChecksums" do
  def assert_checksum(expected, filename)
    filepath = Rails.root.join(filename)
    checksum = Digest::MD5.hexdigest(File.read(filepath))
    assert checksum.in?(Array(expected)), "Bad checksum for file: #{filename}, local version should be reviewed: checksum=#{checksum}, expected=#{Array(expected).join(" or ")}"
  end

  it "should core blocks checksums" do
    # tbody in index view is overridden and should be reviewed each time it changes (copy/paste from core file in override)
    assert_checksum %w(c41a00ab7905f8a76af5471aebcc702b b5709933b0adc728ca69ebe90b4cb9ea fb6cbf9eb0ac7abd08916d97c1fdd183), "app/views/roles/index.html.erb"
  end

  it "should repeat any change in my/page" do
    # my/page is completely overriden, and any future change should be copied to the plugin
    assert_checksum %w(f724b9bb0ffe7cf73cf9ffa162768699), "app/views/my/page.html.erb"
  end

end
