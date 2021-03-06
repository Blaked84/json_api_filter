module JsonApiFilter
  class Dispatch
  
    attr_reader :params, :scope, :allowed_filters, :allowed_searches
    
    # @param [ActiveRecord::Base] scope
    # @param [Hash, ActionController::Parameters] params
    # @param [Array<Symbol>] allowed_filters
    def initialize(scope, params, allowed_filters:, allowed_searches:)
      @params = params
      @scope = scope
      @allowed_filters = allowed_filters
      @allowed_searches = allowed_searches
    end

    # @return [ActiveRecord_Relation]
    def process
      @scope = [
        scope.all,
        sort_predicate,
        filters_predicate,
        search_predicate,
        join_predicate,
      ].compact.reduce(&:merge)
      return scope if params[:pagination].nil?
      scope.merge(pagination_predicate)
    end
    
    private
    
    # @return [ActiveRecord::Base, NilClass]
    def filters_predicate
      #TODO: split this method
      parser_params.fetch('filter', {}).map do |key, value|
        next unless filters.include?(key)

        if nested_filters.include?(key.to_sym)
          next ::JsonApiFilter::FieldFilters::Matcher.new(
            scope,
            {key => value},
            association: true
          )
        end

        if value.class != ActiveSupport::HashWithIndifferentAccess
          next ::JsonApiFilter::FieldFilters::Matcher.new(scope, {key => value})
        end
        
        ::JsonApiFilter::FieldFilters::Compare.new(
          scope,
          {key => value},
          allowed_searches: allowed_searches
        )
      end.compact.map(&:predicate).reduce(&:merge)
    end

    # @return [ActiveRecord::Base, NilClass]
    def sort_predicate
      sort = parser_params[:sort]
      return nil if sort.blank?
      
      ::JsonApiFilter::FieldFilters::Sorter.new(scope, sort).predicate
    end

    # @return [ActiveRecord::Base, NilClass]
    def search_predicate
      return nil if parser_params[:search].blank?
      return nil if allowed_searches[:global].nil?
      
      ::JsonApiFilter::FieldFilters::Searcher.new(
        scope,
        {allowed_searches[:global] => parser_params[:search]}
      ).predicate
    end

    # @return [ActiveRecord::Base, NilClass]
    def pagination_predicate
      return nil if parser_params[:pagination].nil?
      
      ::JsonApiFilter::FieldFilters::Pagination.new(
        scope,
        parser_params[:pagination]
      ).predicate
    end

    # @return [ActiveRecord::Base, NilClass]
    def join_predicate
      parser_params.fetch('filter', {}).map do |key, value|
        next unless nested_filters.include?(key.to_sym)
        
        ::JsonApiFilter::AutoJoin.new(scope, key)
      end.compact.map(&:predicate).reduce(&:merge)
    end
    
    # @return [Hash]
    def parser_params
      return params.to_unsafe_h if params.class == ActionController::Parameters
      
      params
    end
    
    # @return [Hash]
    def filters
      FilterAttributes.new(allowed_filters, parser_params[:filter]).process
    end

    def nested_filters
      FilterAttributes.new(allowed_filters, parser_params[:filter]).nested_allowed_filter
    end
    
  end
end
