require File.dirname(__FILE__) + '/spec_helper'

describe I18n::Backend::Database do
  before(:each) do
    @backend = I18n::Backend::Database.new
  end

  after(:each) do
    @backend.cache_store.clear
  end

  describe "with default locale en" do
    before(:each) do
      I18n.default_locale = "en"
      @english_locale = Locale.create!(:code => "en")
    end

    describe "and locale en" do
      before(:each) do
        I18n.locale = "en"
      end

      it "should create a record with the key as the value when the key is a string" do
        @backend.translate("en", "String").should == "String"
        @english_locale.should have(1).translation
        @english_locale.translations.first.key.should == Translation.hk("String")
        @english_locale.translations.first.raw_key.should == "String"
        @english_locale.translations.first.value.should == "String"
      end

      it "should find a record with the key as the value when the key is a string" do
        @english_locale.translations.create!(:key => 'String', :value => 'Value')
        @backend.translate("en", "String").should == "Value"
        @english_locale.should have(1).translation
      end

      it "should support having a record with a nil value" do
        @english_locale.translations.create!(:key => 'date.order')
        @backend.translate("en", :'date.order').should be_nil
        @english_locale.should have(1).translation
      end

      it "should create a record with a nil value when key is a symbol" do
        @backend.translate("en", :'date.order').should be_nil
        @english_locale.should have(1).translation
        @english_locale.translations.first.key.should == Translation.hk('date.order')
        @english_locale.translations.first.raw_key.should == "date.order"
        @english_locale.translations.first.value.should be_nil
      end

      it "should find a cached record from a cache key if it exists in the cache" do
        hash_key = Translation.hk("blah")
        @backend.cache_store.write("en:#{hash_key}:1", 'woot')
        @backend.translate("en", "blah").should == "woot"
      end

      it "should find a cached record with a nil value from a cache key if it exists in the cache" do
        hash_key = Translation.hk(".date.order")
        @backend.cache_store.write("en:#{hash_key}:1", nil)
        @backend.translate("en", :'date.order').should be_nil
      end

      it "should write a cache record to the cache for a newly created translation record" do
        hash_key = Translation.hk("blah")
        @backend.translate("en", "blah")
        @backend.cache_store.read("en:#{hash_key}:1").should == "blah"
      end

      it "should write a cache record to the cache for translation record with nil value" do
        @english_locale.translations.create!(:key => '.date.order')
        @backend.translate("en", :'date.order').should be_nil

        hash_key = Translation.hk(".date.order")
        @backend.cache_store.read("en:#{hash_key}:1").should be_nil
      end

      it "should handle active record helper defaults, where default is the object name" do
        options = {:count=>1, :scope=>[:activerecord, :models], :default=>"post"}
        @english_locale.translations.create!(:key => 'activerecord.errors.models.blank', :value => 'post')
        @backend.translate("en", :"models.blank", options).should == 'post'
      end

      it "should be able to handle interpolated values" do
        options = {:some_value => 'INTERPOLATED'}
        @english_locale.translations.create!(:key => 'Fred', :value => 'Fred has been {{some_value}}!!')
        @backend.translate("en", 'Fred', options).should == 'Fred has been INTERPOLATED!!'
      end

      it "should be able to handle interpolated values with 'Fred {{some_value}}' also as the key" do
        options = {:some_value => 'INTERPOLATED'}
        @english_locale.translations.create!(:key => 'Fred {{some_value}}', :value => 'Fred {{some_value}}!!')
        @backend.translate("en", 'Fred {{some_value}}', options).should == 'Fred INTERPOLATED!!'
      end

      it "should be able to handle interpolated count values" do
        options = {:count=>1, :model => ["Cheese"], :scope=>[:activerecord, :errors], :default=>["Locale"]}
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => '{{count}} errors prohibited this {{model}} from being saved')
        @backend.translate("en", :"messages.blank", options).should == '1 errors prohibited this Cheese from being saved'
      end

      it "should be able to handle the case of scope being passed in as something other than an array" do
        options = {:count=>1, :model => ["Cheese"], :scope=> :activerecord, :default=>["Locale"]}
        @english_locale.translations.create!(:key => 'activerecord.messages.blank', :value => 'dude')
        @backend.translate("en", :"messages.blank", options).should == 'dude'
      end

      it "should be able to handle pluralization" do
        @english_locale.translations.create!(:key => 'activerecord.errors.template.header', :value => '1 error prohibited this {{model}} from being saved', :pluralization_index => 1)
        @english_locale.translations.create!(:key => 'activerecord.errors.template.header', :value => '{{count}} errors prohibited this {{model}} from being saved', :pluralization_index => 0)

        options = {:count=>1, :model=>"translation", :scope=>[:activerecord, :errors, :template]}
        @backend.translate("en", :"header", options).should == "1 error prohibited this translation from being saved"
        @english_locale.should have(2).translations

        options = {:count=>2, :model=>"translation", :scope=>[:activerecord, :errors, :template]}
        @backend.translate("en", :"header", options).should == "2 errors prohibited this translation from being saved"
        @english_locale.should have(2).translations
      end

      it "should find lowest level translation" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')

        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", :"messages.blank"], :model=>"Translation"}

        @backend.translate("en", :"models.translation.attributes.locale.blank", options).should == "is blank moron!"
      end

      it "should find higher level translation" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')
        @english_locale.translations.create!(:key => 'activerecord.errors.models.translation.blank', :value => 'translation blank')

        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", :"messages.blank"], :model=>"Translation"}

        @backend.translate("en", :"models.translation.attributes.locale.blank", options).should == "translation blank"
      end

      it "should find highest level translation" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')
        @english_locale.translations.create!(:key => 'activerecord.errors.models.translation.blank', :value => 'translation blank')
        @english_locale.translations.create!(:key => 'activerecord.errors.models.translation.attributes.locale.blank', :value => 'translation locale blank')

        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", :"messages.blank"], :model=>"Translation"}

        @backend.translate("en", :"models.translation.attributes.locale.blank", options).should == "translation locale blank"
      end

      it "should create the translation for custom message" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')

        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", "This is a custom message!", :"messages.blank"], :model=>"Translation"}

        @backend.translate("en", :"models.translation.attributes.locale.blank", options).should == "This is a custom message!"
        @english_locale.should have(2).translations
        @english_locale.translations.find_by_key(Translation.hk("This is a custom message!")).value.should == 'This is a custom message!'
      end

      it "should find the translation for custom message" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')
        @english_locale.translations.create!(:key => 'This is a custom message!', :value => 'This is a custom message!')

        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", "This is a custom message!", :"messages.blank"], :model=>"Translation"}

        @backend.translate("en", :"models.translation.attributes.locale.blank", options).should == "This is a custom message!"
      end

      it "should NOT find the translation for custom message" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')
        @english_locale.translations.create!(:key => 'This is a custom message!', :value => 'This is a custom message!')

        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", :"messages.blank"], :model=>"Translation"}

        @backend.translate("en", :"models.translation.attributes.locale.blank", options).should == "is blank moron!"
      end

    end

    describe "and locale es" do
      before(:each) do
        I18n.locale = "es"
        @spanish_locale = Locale.create!(:code => 'es')
      end

      it "should create a record with a nil value when the key is a string" do
        @backend.translate("es", "String")
        @spanish_locale.should have(1).translation
        @spanish_locale.translations.first.key.should == Translation.hk("String")
        @spanish_locale.translations.first.value.should be_nil
      end

      it "should return default locale (en) value and create the spanish record" do
        @english_locale.translations.create!(:key => 'String', :value => 'English String')
        @backend.translate("es", "String").should == "English String"
        @spanish_locale.should have(1).translation
      end

      it "should return just the passed in value when no translated record and no default translation" do
        @backend.translate("es", "String").should == "String" 
        @spanish_locale.should have(1).translation
      end

      it "should support having a default locale record with a nil value" do
        @english_locale.translations.create!(:key => 'date.order')
        @backend.translate("es", :'date.order').should be_nil

        @spanish_locale.should have(1).translation
        @spanish_locale.translations.first.key.should == Translation.hk('date.order')
        @spanish_locale.translations.first.value.should be_nil
      end

      it "should be able to handle interpolated values" do
        options = {:some_value => 'INTERPOLATED'}
        @english_locale.translations.create!(:key => 'Fred', :value => 'Fred has been {{some_value}}!!')
        @spanish_locale.translations.create!(:key => 'Fred', :value => 'Fred ha sido {{some_value}}!!')
        @backend.translate("es", 'Fred', options).should == 'Fred ha sido INTERPOLATED!!'
      end

      it "should be able to handle interpolated count values" do
        options = {:count=>1, :model => ["Cheese"], :scope=>[:activerecord, :errors], :default=>["Locale"]}
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => '{{count}} error prohibited this {{model}} from being saved')
        @backend.translate("es", :"messages.blank", options).should == '1 error prohibited this Cheese from being saved'
      end

      it "should be able to handle pluralization" do
        @english_locale.translations.create!(:key => 'activerecord.errors.template.header', :value => '1 error prohibited this {{model}} from being saved', :pluralization_index => 1)
        @english_locale.translations.create!(:key => 'activerecord.errors.template.header', :value => '{{count}} errors prohibited this {{model}} from being saved', :pluralization_index => 0)
        options = {:count=>1, :model=>"translation", :scope=>[:activerecord, :errors, :template]}
        @backend.translate("es", :"header", options).should == "1 error prohibited this translation from being saved"
        @spanish_locale.should have(1).translations

        options = {:count=>2, :model=>"translation", :scope=>[:activerecord, :errors, :template]}
        @backend.translate("es", :"header", options).should == "2 errors prohibited this translation from being saved"
        @spanish_locale.reload.should have(2).translations
      end

      it "should find lowest level translation" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')

        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", :"messages.blank"], :model=>"Translation"}

        @backend.translate("es", :"models.translation.attributes.locale.blank", options).should == "is blank moron!"

        @spanish_locale.should have(1).translation
        @spanish_locale.translations.first.key.should == Translation.hk("activerecord.errors.messages.blank")
        @spanish_locale.translations.first.value.should be_nil
      end

      it "should find higher level translation" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')
        @english_locale.translations.create!(:key => 'activerecord.errors.models.translation.blank', :value => 'translation blank')

        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", :"messages.blank"], :model=>"Translation"}

        @backend.translate("es", :"models.translation.attributes.locale.blank", options).should == "translation blank"
        @spanish_locale.should have(1).translation
        @spanish_locale.translations.first.key.should == Translation.hk("activerecord.errors.models.translation.blank")
        @spanish_locale.translations.first.value.should be_nil
        @backend.cache_store.read("es:activerecord.errors.models.translation.blank:1", "translation blank")
      end

      it "should find highest level translation" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')
        @english_locale.translations.create!(:key => 'activerecord.errors.models.translation.blank', :value => 'translation blank')
        @english_locale.translations.create!(:key => 'activerecord.errors.models.translation.attributes.locale.blank', :value => 'translation locale blank')

        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", :"messages.blank"], :model=>"Translation"}

        @backend.translate("es", :"models.translation.attributes.locale.blank", options).should == "translation locale blank"
        @spanish_locale.should have(1).translation
        @spanish_locale.translations.first.key.should == Translation.hk("activerecord.errors.models.translation.attributes.locale.blank")
        @spanish_locale.translations.first.value.should be_nil
      end

      it "should find the translation for custom message" do
        @english_locale.translations.create!(:key => 'activerecord.errors.messages.blank', :value => 'is blank moron!')
        @english_locale.translations.create!(:key => 'This is a custom message!', :value => 'This is a custom message!')

        options = {:attribute=>"Locale", :value=>nil, 
          :scope=>[:activerecord, :errors], :default=>[:"models.translation.blank", "This is a custom message!", :"messages.blank"], :model=>"Translation"}

        @backend.translate("es", :"models.translation.attributes.locale.blank", options).should == "This is a custom message!"
        @spanish_locale.should have(1).translation
        @spanish_locale.translations.first.key.should == Translation.hk("This is a custom message!")
        @spanish_locale.translations.first.value.should be_nil
      end
    end
  end
end
