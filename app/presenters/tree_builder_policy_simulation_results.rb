class TreeBuilderPolicySimulationResults < TreeBuilder
  # exp_build_string method needed
  include ApplicationController::ExpressionHtml

  has_kids_for Hash, [:x_get_tree_hash_kids]

  def initialize(name, type, sandbox, build = true, root = nil)
    @root = root
    super(name, type, sandbox, build)
  end

  private

  def tree_init_options(_tree_name)
    {:full_ids => true, :lazy => false}
  end

  def set_locals_for_render
    locals = super
    locals.merge!(:id_prefix                   => "rsop_",
                  :autoload                    => true,
                  :cfme_no_click               => true,
                  :onclick                     => false,
                  :open_close_all_on_dbl_click => true,)
  end

  def root_options
    event = MiqEventDefinition.find(@root[:event_value])
    [_("Policy Simulation Results for Event [%{description}]") % {:description => event.description},
     nil,
     "event-#{event.name}",
     {:cfmeNoClick => true}]
  end

  def node_icon(result)
    case result
    when 'allow' then 'checkmark'
    when 'N/A'   then 'na'
    else 'x'
    end
  end

  def vm_nodes(data)
    data.sort_by! { |a| a[:name].downcase }.map do |node|
      {:id => node[:id],
       :text => "<strong>VM:</strong> #{node[:name]}".html_safe,
       :image => 'vm',
       :profiles => node[:profiles]}
    end
  end



  def pofile_nodes(data)
    data.sort_by { |a| a[:name].downcase }.map do |node|
      {:id => node[:id],
       :text => "<strong>#{_('Profile:')}</strong> #{node[:description]}".html_safe,
       :image => node_icon(node[:result]),
       :policies => node[:policies]}
    end
  end

  def policy_nodes(data)
    #TODO remove node
    data.sort_by { |a| a[:name].downcase }.map do |node|
      active_caption = node[:active] ? "" : "(Inactive)"
       {:id => node['id'],
           :text => "<strong>Policy#{active_caption}:</strong> #{node[:description]}".html_safe,
           :image => node_icon(node[:result]),
      :conditions => node[:conditions],
      :actions => node[:actions],
      :scope => node[:scope]}
    end
  end

  def action_nodes(data)
    data.map do |node|
      {:id => node[:id],
       :text => "<strong>#{_('Action:')}</strong> #{node[:description]}".html_safe,
       :image => node_icon(node[:result])}
    end
  end

  def condition_nodes(data)
    data.map do |node|
      {:id => node[:id],
                 :text => "<strong>#{_('Condition:')}</strong> #{node[:description]}".html_safe,
                 :image => node_icon(node[:result]),
           :expression => node[:expression]}
    end
  end

  def scope_node(data)
    name, tip = exp_build_string(data)
    {:id => nil,
     :text => "<style>span.ws-wrap { white-space: normal; }</style><strong>#{_('Scope:')}</strong> <span class='ws-wrap'>#{name}".html_safe,
     :tip   => tip.html_safe,
     :image => node_icon(data[:result])}
  end

  def expression_node(data)
    name, tip = exp_build_string(data)
    {:id    => nil,
     :text  => "<style>span.ws-wrap { white-space: normal; }</style><strong>#{_('Expression:')}</strong> <span class='ws-wrap'>#{name}".html_safe,
     :tip   => tip.html_safe,
     :image => 'na'}

  end

  def x_get_tree_roots(count_only = false, _options)
    count_only_or_objects(count_only, vm_nodes(@root[:results]))
  end

  def x_get_tree_hash_kids(parent, count_only)
    kids = []
    kids.concat(pofile_nodes(parent[:profiles])) if parent[:profiles].present?
    kids.concat(policy_nodes(parent[:policies])) if parent[:policies].present?
    kids.concat(condition_nodes(parent[:conditions])) if parent[:conditions].present?
    kids.push(scope_node(parent[:scope])) if parent[:scope].present?
    kids.push(expression_node(parent[:expression])) if parent[:expression].present?
    kids.concat(action_nodes(parent[:actions])) if parent[:actions].present?
    count_only_or_objects(count_only, kids)
  end
end