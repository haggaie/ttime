require 'logic/course'
require 'gui/progress_dialog'
require 'libglade2'
require 'data'
require 'gtkmozembed'
require 'tempfile'

module TTime
  module GUI
    class MainWindow
      GLADE_FILE = "gui/ttime.glade"
      def initialize
        @glade = GladeXML.new(GLADE_FILE) { |handler| method(handler) }

        @selected_courses = []

        @tree_available_courses = Gtk::TreeStore.new String, String,
          Logic::Course
        @list_selected_courses = Gtk::ListStore.new String, String,
          Logic::Course

        init_course_tree_views
        init_schedule_view

        load_data
      end

      def on_quit_activate
        Gtk.main_quit
      end

      def on_about_activate
        @glade["AboutDialog"].run
      end

      def on_add_course
        course = currently_addable_course

        if course
          @selected_courses << course

          iter = @list_selected_courses.append
          iter[0] = course.number
          iter[1] = course.name
          iter[2] = course

          on_available_course_selection
          on_selected_course_selection
        end
      end

      def on_remove_course
        iter = currently_removable_course_iter

        if iter
          @selected_courses.delete iter[2]
          @list_selected_courses.remove iter

          on_available_course_selection
          on_selected_course_selection
        end
      end

      def on_available_course_selection
        course = currently_addable_course

        @glade["btn_add_course"].sensitive = 
          course ? true : false

        if course
          set_course_info course.text
        end
      end

      def on_selected_course_selection
        course_iter = currently_removable_course_iter
        @glade["btn_remove_course"].sensitive =
          course_iter ? true : false

        if course_iter
          set_course_info course_iter[2].text
        end
      end

      private

      def init_schedule_view
        notebook = @glade["notebook"]
        @mozembed = Gtk::MozEmbed.new
        notebook.append_page @mozembed, Gtk::Label.new("Schedule")

        notebook.show_all

#        @mozembed.location = 'http://yasmin.technion.ac.il'

        set_current_schedule(nil)
      end

      def set_current_schedule(schedule)
        # FIXME: This should get a schedule and display it
        @sched_html_file.unlink if @sched_html_file

        @sched_html_file = Tempfile.new("schedule")

        File.open("gui/html/SchedTable_pre.html") do |f|
          @sched_html_file.write f.read
        end

        File.open("gui/html/example.js") do |f|
          @sched_html_file.write f.read
        end

        File.open("gui/html/SchedTable_post.html") do |f|
          @sched_html_file.write f.read
        end

        @sched_html_file.close

        @mozembed.location = 'file://' + @sched_html_file.path
      end

      def set_course_info(info)
        @glade["text_course_info"].buffer.text = info
      end

      def currently_addable_course
        available_courses_view = @glade["treeview_available_courses"]

        selected_iter = available_courses_view.selection.selected

        return false unless selected_iter

        return false if @selected_courses.include? selected_iter[2]

        selected_iter[2]
      end

      def currently_removable_course_iter
        selected_courses_view = @glade["treeview_selected_courses"]

        selected_iter = selected_courses_view.selection.selected

        return false unless selected_iter

        selected_iter
      end

      def load_data
        progress_dialog = ProgressDialog.new

        Thread.new do
          @data = TTime::Data.load(&progress_dialog.get_status_proc)

          progress_dialog.dispose

          update_available_courses_tree
        end
      end

      def update_available_courses_tree
        @tree_available_courses.clear

        progress_dialog = ProgressDialog.new
        progress_dialog.text = 'Populating available courses'

        Thread.new do
          @data.each_with_index do |faculty,i|
            progress_dialog.fraction = i.to_f / @data.size.to_f

            iter = @tree_available_courses.append(nil)
            iter[0] = faculty.name

            faculty.courses.each do |course|
              child = @tree_available_courses.append(iter)
              child[0] = course.number
              child[1] = course.name
              child[2] = course
            end
          end
          
          progress_dialog.dispose
        end
      end

      def init_course_tree_views
        available_courses_view = @glade["treeview_available_courses"]
        available_courses_view.model = @tree_available_courses

        selected_courses_view = @glade["treeview_selected_courses"]
        selected_courses_view.model = @list_selected_courses

        columns = []

        [ "Course No.", "Course Name" ].each_with_index do |label, i|
          columns[i] = Gtk::TreeViewColumn.new label, Gtk::CellRendererText.new,
            :text => i
        end

        columns.each do |c|
          available_courses_view.append_column c
        end

        # This actually has to be done twice, because we need different
        # copies of the columns for each of the views

        [ "Course No.", "Course Name" ].each_with_index do |label, i|
          columns[i] = Gtk::TreeViewColumn.new label, Gtk::CellRendererText.new,
            :text => i
        end

        columns.each do |c|
          selected_courses_view.append_column c
        end
      end
    end
  end
end
