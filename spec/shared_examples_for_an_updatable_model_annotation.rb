# These shared examples are used to test updating existing annotations in a
# model.
#
# @note They expect `base_options` to be set before running.
RSpec.shared_examples "an updatable model annotation" do
  let(:options) { base_options.merge(context_options)  }
  let(:context_options) { {} }

  describe 'adding a new field' do
    let(:class_name) { :users }
    let(:primary_key) { :id }
    let(:original_columns) do
      [
        mock_column(primary_key, :integer),
        mock_column(:name, :integer)
      ]
    end

    before do
      klass = mock_class(class_name, primary_key, original_columns)
      @schema_info = AnnotateModels.get_schema_info(klass, '== Schema Info', options)
      annotate_one_file(options)

      # confirm we initialized annotaions in file before checking for changes
      expect(@schema_info).not_to be_empty
      expect(File.read(@model_file_name)).to eq("#{@schema_info}#{@file_content}")
    end


    it 'updates the fields list to include the new column' do
      # We make the new column type ":string" because we don't currently have a
      # string type. This makes our later check for "string" less likely to
      # result in a false positive.
      new_column_list = original_columns + [mock_column(:new_column, :string)]
      klass = mock_class(class_name, primary_key, new_column_list)
      @schema_info = AnnotateModels.get_schema_info(klass, '== Schema Info', options)
      annotate_one_file(options)

      file = File.read(@model_file_name)
      expect(@schema_info).to match(/new_column/)
      # some annotations have the type of the column on a new line, so we
      # cannot expect the column name and type to be on the same line
      expect(@schema_info).to match(/string/i)
      expect(file).to eq("#{@schema_info}#{@file_content}")
    end
  end

  describe 'changing a field type' do
    let(:class_name) { :users }
    let(:primary_key) { :id }
    let(:original_columns) do
      [
        mock_column(primary_key, :integer),
        mock_column(:some_field, :string)
      ]
    end

    # update `name` from `:string` to `:text`
    let(:new_column_list) do
      [
        mock_column(primary_key, :integer),
        mock_column(:some_field, :integer)
      ]
    end

    before do
      klass = mock_class(class_name, primary_key, original_columns)
      @schema_info = AnnotateModels.get_schema_info(klass, '== Schema Info', options)
      annotate_one_file(options)

      # confirm we initialized annotaions in file before checking for changes
      expect(@schema_info).not_to be_empty
      expect(File.read(@model_file_name)).to eq("#{@schema_info}#{@file_content}")
    end

    it 'updates the fields list to include the new column' do
      klass = mock_class(class_name, primary_key, new_column_list)
      @schema_info = AnnotateModels.get_schema_info(klass, '== Schema Info', options)
      annotate_one_file(options)

      expect(File.read(@model_file_name)).to eq("#{@schema_info}#{@file_content}")
    end
  end

  describe 'position' do
    let(:context_options) { { position: starting_position } }

    before do
      debugger
      annotate_one_file(options)

      # not usre why this needs to happen
      another_schema_info = AnnotateModels.get_schema_info(mock_class(:users, :id, [mock_column(:id, :integer)]), '== Schema Info', )
      @schema_info = another_schema_info

      # confirm we initialized annotatoins in file before checking for changes
      expect(@schema_info).not_to be_empty
      expect(File.read(@model_file_name)).to eq("#{@schema_info}#{@file_content}")
    end

    # TODO these don't seem to work
    describe "with existing annotation => 'before'" do
      let(:starting_position) { 'before' }

      it 'should retain current position' do
        annotate_one_file(options)

        expect(File.read(@model_file_name)).to eq("#{@schema_info}#{@file_content}")
      end

      it "should retain current position even when :position is changed to 'after'" do
        annotate_one_file(options.merge({ position: 'after' }))
        expect(File.read(@model_file_name)).to eq("#{@schema_info}#{@file_content}")
      end

      it "should change position to 'after' when force: true" do
        debugger
        annotate_one_file(options.merge({ position: 'after', force: true }))
        expect(File.read(@model_file_name)).to eq("#{@file_content}\n#{@schema_info}")
      end
    end

    describe "with existing annotation => 'after'" do
      let(:starting_position) { 'after' }

      it 'should retain current position' do
        annotate_one_file(options)
        expect(File.read(@model_file_name)).to eq("#{@file_content}\n#{@schema_info}")
      end

      it "should retain current position even when :position is changed to 'before'" do
        annotate_one_file(options.merge({ position: 'before' }))
        expect(File.read(@model_file_name)).to eq("#{@file_content}\n#{@schema_info}")
      end

      it "should change position to 'before' when force: true" do
        annotate_one_file(options.merge({ position: 'before', force: true }))
        expect(File.read(@model_file_name)).to eq("#{@schema_info}#{@file_content}")
      end
    end
  end

  describe 'updating a foreign key' do
    before do
      klass = mock_class(:users,
                         :id,
                         [
                           mock_column(:id, :integer),
                           mock_column(:foreign_thing_id, :integer)
                         ],
                         [],
                         [
                           mock_foreign_key('fk_rails_cf2568e89e',
                                            'foreign_thing_id',
                                            'foreign_things',
                                            'id',
                                            on_delete: :cascade)
                         ])
      @schema_info = AnnotateModels.get_schema_info(klass, '== Schema Info', show_foreign_keys: true)
      annotate_one_file
    end

    it 'should update foreign key constraint' do
      klass = mock_class(:users,
                         :id,
                         [
                           mock_column(:id, :integer),
                           mock_column(:foreign_thing_id, :integer)
                         ],
                         [],
                         [
                           mock_foreign_key('fk_rails_cf2568e89e',
                                            'foreign_thing_id',
                                            'foreign_things',
                                            'id',
                                            on_delete: :restrict)
                         ])
      @schema_info = AnnotateModels.get_schema_info(klass, '== Schema Info', show_foreign_keys: true)
      annotate_one_file
      # debugger
      expect(File.read(@model_file_name)).to eq("#{@schema_info}#{@file_content}")
    end
  end
end

