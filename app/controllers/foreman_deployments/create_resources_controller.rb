module ForemanDeployments
  #
  class CreateResourcesController < ApplicationController
    def index
    end

    def new
      @resource = ResourceModels::CreateResource.new
      @resource.resource_type = User
      @resource.definition_hash = {
        login: 'my_user1',
        mail: 'test@foreman.org'
      }

      @user = @resource.new_resource
    end

    # rubocop:disable Metrics/MethodLength
    def create
      params[:user].delete :admin

      # register tasks
      ForemanDeployments.tasks.register_task('CreateResource', Tasks::CreationTaskDefinition)

      # stack definition
      # will be selected from DB as Stack object
      stack = [
        'user1: !task:CreateResource',
        '  klass: User',
        '  params:',
        '    mail: test@foreman.org',
        'usergroup1: !task:CreateResource',
        '  klass: Usergroup',
        '  params:',
        '    name: zzz',
        '    user_ids:',
        '      - !reference',
        '        object: user1',
        '        field: object.id'
      ].join("\n")

      # parse the stack
      stack_definition = ForemanDeployments::StackParser.parse(stack)

      # configure with user input
      stack_definition.tasks['user1'].configure('params' => params[:user])
      stack_definition.tasks['usergroup1'].configure({})

      # validate
      result = ForemanDeployments::Validation::Validator.validate(stack_definition)
      fail "Validation failed:\n #{result.messages}" unless result.valid?

      ForemanTasks.sync_task(Tasks::StackDeployAction, stack_definition)

      redirect_to foreman_tasks_tasks_path
    end

    def edit
    end

    def update
    end

    def destroy
    end
  end
end
