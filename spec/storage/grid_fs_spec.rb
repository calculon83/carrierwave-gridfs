
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
36
37
38
39
40
41
42
43
44
45
46
47
48
49
50
51
52
53
54
55
56
57
58
59
60
61
62
63
64
65
66
67
68
69
70
71
72
73
74
75
76
77
78
79
80
81
82
83
84
85
86
87
88
89
90
91
# encoding: utf-8

require 'spec_helper'
require 'mongo'

describe CarrierWave::Storage::GridFS do

  before do
    @database = Mongo::Connection.new('localhost', 27017).db('carrierwave_test')
    @uploader = mock('an uploader')
    @uploader.stub!(:grid_fs_database).and_return("carrierwave_test")
    @uploader.stub!(:grid_fs_host).and_return("localhost")
    @uploader.stub!(:grid_fs_port).and_return(27017)
    @uploader.stub!(:grid_fs_access_url).and_return(nil)
    @uploader.stub!(:grid_fs_username).and_return(nil)
    @uploader.stub!(:grid_fs_password).and_return(nil)
    
    @grid = Mongo::GridFileSystem.new(@database)

    @storage = CarrierWave::Storage::GridFS.new(@uploader)
    @file = stub_tempfile('test.jpg', 'application/xml')
  end
  
  after do
    @grid.delete('uploads/bar.txt')
  end

  describe '#store!' do
    before do
      @uploader.stub!(:store_path).and_return('uploads/bar.txt')
      @grid_fs_file = @storage.store!(@file)
    end
    
    it "should upload the file to gridfs" do
      @grid.open('uploads/bar.txt', 'r').data.should == 'this is stuff'
    end
    
    it "should not have a path" do
      @grid_fs_file.path.should be_nil
    end
    
    it "should not have a URL" do
      @grid_fs_file.url.should be_nil
    end
    
    it "should be deletable" do
      @grid_fs_file.delete
      lambda {@grid.open('uploads/bar.txt', 'r')}.should raise_error(Mongo::GridFileNotFound)
    end
    
    it "should store the content type on GridFS" do
      @grid_fs_file.content_type.should == 'application/xml'
    end
    
    it "should have a file length" do
      @grid_fs_file.file_length.should == 13
    end
    
  end
  
  describe '#retrieve!' do
    before do
      @grid.open('uploads/bar.txt', 'w') { |f| f.write "A test, 1234" }
      @uploader.stub!(:store_path).with('bar.txt').and_return('uploads/bar.txt')
      @grid_fs_file = @storage.retrieve!('bar.txt')
    end

    it "should retrieve the file contents from gridfs" do
      @grid_fs_file.read.chomp.should == "A test, 1234"
    end
    
    it "should not have a path" do
      @grid_fs_file.path.should be_nil
    end
    
    it "should not have a URL unless set" do
      @grid_fs_file.url.should be_nil
    end
    
    it "should return a URL if configured" do
      @uploader.stub!(:grid_fs_access_url).and_return("/image/show")
      @grid_fs_file.url.should == "/image/show/uploads/bar.txt"
    end
    
    it "should be deletable" do
      @grid_fs_file.delete
      lambda {@grid.open('uploads/bar.txt', 'r')}.should raise_error(Mongo::GridFileNotFound)
    end
  end

end
