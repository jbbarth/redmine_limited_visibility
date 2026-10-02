require 'spec_helper'

describe "FileChecksums" do
  def assert_checksum(expected, filename)
    filepath = Rails.root.join(filename)
    checksum = Digest::MD5.hexdigest(File.read(filepath))
    assert checksum.in?(Array(expected)), "Bad checksum for file: #{filename}, local version should be reviewed: checksum=#{checksum}, expected=#{Array(expected).join(" or ")}"
  end

  it "should core blocks checksums" do
    # tbody in index view is overridden and should be reviewed each time it changes (copy/paste from core file in override)
    assert_checksum %w(ab1a2d08e1b058f6b8ae0466dce9e679), "app/views/roles/index.html.erb"
  end

  it "should repeat any change in my/page" do
    # my/page is completely overridden, and any future change should be copied to the plugin
    assert_checksum %w(906a83136fed11e7e1bea073e767eadb), "app/views/my/page.html.erb"
  end

  it "should break if issues and projects api are updated" do
    # issues & projects API are completely overridden, and any future change should be copied to the plugin
    assert_checksum %w(af0bf4c2e7ef1b9f9be182b805d914c3), "app/views/projects/index.api.rsb"
    assert_checksum %w(793015fe562e10cd3c8922e49366b90c), "app/views/projects/show.api.rsb"
    assert_checksum %w(febf44762ccab7791a41390634b3d541 000460f205338921484279d56c026b0a), "app/views/issues/index.api.rsb"
    assert_checksum %w(b28a2d536393ccc96458a5c3a81d70dd 0a168b71f1d84c5f2063a77fec84eb25), "app/views/issues/show.api.rsb"
    assert_checksum %w(173f425fb9f6bbc4b3c964ad7eb9c302), "app/views/users/show.api.rsb"
  end

end
