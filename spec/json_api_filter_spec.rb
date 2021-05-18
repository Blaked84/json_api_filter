RSpec.describe JsonApiFilter do

  before do
    class FakesController
      include ::JsonApiFilter
      permitted_filters  [:id, :author, :name, posts: [:id], articles: [:id]]
      permitted_searches :fake_global_search,
                         name: :fake_name_search
    end
  end
  after { Object.send :remove_const, :FakesController }
  let(:object) { FakesController.new }
  klass_examples = [
      {
        name: "JsonApiFilter::Dispatch",
        examples: [
          {
            name: 'nothing 😉',
            params: {},
            request: User.all
          },
        ],
      },
      {
        name: "JsonApiFilter::FieldFilters::Matcher",
        examples: [
          {
            name: 'direct id',
            params: {
              filter: { id: "1,2" }
            },
            request: User.where(id: [1,2])
          },
          {
            name: 'empty id',
            params: {
              filter: { id: "" }
            },
            request: User.where(id: '')
          },
       ],
      },
      {
        name: "JsonApiFilter::FieldFilters::Compare",
        examples: [
          {
            name: 'eq id',
            params: {
              filter: { id: {eq: 1} }
            },
            request: User.where("id" => "1")
          },
          {
            name: 'not eq id',
            params: {
              filter: { id: {ne: 1} }
            },
            request: User.where("id != 1")
          },
          {
            name: 'gt id',
            params: {
              filter: { id: {gt: 1} }
            },
            request: User.where("id > 1")
          },
          {
            name: 'ge id',
            params: {
              filter: { id: {ge: 1} }
            },
            request: User.where("id >= 1")
          },
          {
            name: 'lt id',
            params: {
              filter: { id: {lt: 1} }
            },
            request: User.where("id < 1")
          },
          {
            name: 'le id',
            params: {
              filter: { id: {le: 1} }
            },
            request: User.where("id <= 1")
          },
          {
            name: 'le id and gt id',
            params: {
              filter: {
                id: {
                  gt: 1,
                  lt: 3,
                },
              }
            },
            request: User.where("id > 1").where("id < 3")
          },
          {
            name: 'le id and eq name',
            params: {
              filter: {
                id: {le: 1},
                name: {eq: "foo"}
              }
            },
            request: User.where("id <= 1").where("name" => "foo")
          }
       ]
      },
      {
        name: "JsonApiFilter::FieldFilters::Searcher",
        examples: [
          {
            name: "global search",
            params: {
              search: "test user"
            },
            request: User.where("name = 'test user'")
          },
          {
            name: "column search",
            params: {
              filter: {
                name: {
                  search: "test user"
                }
              }
            },
            request: User.where("name = 'test user'")
          }
        ]
      },
      {
        name: "JsonApiFilter::FieldFilters::Sorter",
        examples: [
          {
            name: "sort by id",
            params: {
              sort: {
                by: "id"
              }
            },
            request: User.order(:id)
          },
          {
            name: "sort by descending id",
            params: {
              sort: {
                by: "id",
                desc: true
              }
            },
            request: User.order(id: :desc)
          },
          {
            name: "sort by name",
            params: {
              sort: {
                by: "name"
              }
            },
            request: User.order(:name)
          },
        ]
      },
      {
        name: "JsonApiFilter::FieldFilters::Pagination",
        examples: [
          {
            name: "first page with 10 elements",
            params: {
              pagination: {
                page: 1,
                perPage: 10
              }
            },
            request: User.limit(10).offset(0)
          },
          {
            name: "third page with 5 elements",
            params: {
              pagination: {
                page: 3,
                perPage: 5
              }
            },
            request: User.limit(5).offset(10)
          }
        ]
      },
      {
        name: "JsonApiFilter::FieldFilters::Matcher on associations",
        examples: [
                {
                  name: 'direct multiples id',
                  params: {
                    filter: { posts: {id: "1,2"} }
                  },
                  request: User.joins(:posts)
                               .where(posts: {id: [1,2]})
                },
                {
                  name: 'named relationship',
                  params: {
                    filter: { articles: {id: "1,2"} }
                  },
                  request: User.joins(:articles)
                               .where(posts: {id: [1,2]})
                },
                {
                  name: 'direct one id',
                  params: {
                    filter: { posts: {id: "1"} }
                  },
                  request:  User.joins(:posts)
                                .where(posts: {id: 1})
                },
                {
                  name: 'combined',
                  params: {
                    filter: {
                      posts: {id: "1,2"},
                      name: "foo",
                    }
                  },
                  request: User.joins(:posts)
                               .where(posts: {id: [1,2]})
                               .where(name: "foo")
                },
                {
                  name: 'relationship field',
                  params: {
                    filter: {
                      posts: {user_id: "1,2"},
                    }
                  },
                  request: User.joins(:posts)
                               .where(posts: {user_id: [1,2]})
                },
                {
                  name: 'named relationship field',
                  params: {
                    filter: {
                      articles: {user_id: "1,2"},
                    }
                  },
                  request: User.joins(:posts)
                               .where(posts: {user_id: [1,2]})
                },
              ],
      },
    ]


  klass_examples.each do |klass|
  
    describe klass[:name] do
    
      klass[:examples].each do |test_case|
        tc = test_case.with_indifferent_access
        
        
        it "Filter by #{tc['name']}" do
          expect(object.json_api_filter(User, tc['params'])).to eq(tc['request'])
        end
      end
    end
    
  end

end
