require 'spec_helper'

describe "FileChecksums" do
  def assert_checksum(expected, filename)
    filepath = Rails.root.join(filename)
    checksum = Digest::MD5.hexdigest(File.read(filepath))
    assert checksum.in?(Array(expected)), "Bad checksum for file: #{filename}, local version should be reviewed: checksum=#{checksum}, expected=#{Array(expected).join(" or ")}"
  end

  it "should core blocks checksums" do
    # tbody in index view is overridden and should be reviewed each time it changes (copy/paste from core file in override)
    assert_checksum %w(c5bbcca4fa2ed57299032384413f1db6), "app/views/roles/index.html.erb"
  end

  it "should repeat any change in my/page" do
    # my/page is completely overridden, and any future change should be copied to the plugin
    assert_checksum %w(3e32d220ab995585eadcc4f575b3d640), "app/views/my/page.html.erb"
  end

  it "should break if issues and projects api are updated" do
    # issues & projects API are completely overridden, and any future change should be copied to the plugin
    assert_checksum %w(7ffc3d91fd7a41532030ffa477e9e018), "app/views/projects/index.api.rsb"
    assert_checksum %w(793015fe562e10cd3c8922e49366b90c), "app/views/projects/show.api.rsb"
    assert_checksum %w(143e12b99ab1796616f17c740d50724c), "app/views/issues/index.api.rsb"
    assert_checksum %w(015cf9545f9d4078106b30311ded7f9b), "app/views/issues/show.api.rsb"
  end

end
