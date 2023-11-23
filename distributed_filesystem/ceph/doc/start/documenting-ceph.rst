==================
 Documenting Ceph
==================

You can help the Ceph project by contributing to the documentation.  Even
small contributions help the Ceph project, such as fixing
spelling errors or rewriting confusing instructions.

The easiest way to suggest a correction to the documentation is to send an
email to `ceph-users@ceph.io`. Include the string "ATTN: DOCS" or
"Attention: Docs" or "Attention: Documentation" in the subject line.  In
the body of the email, include the text to be corrected (so that I can find
it in the repo) and include your correction.

Another way to suggest a documentation correction is to make a pull request.
The instructions for making a pull request against the Ceph documentation are
in the section :ref:`making_contributions`.

If this is your first time making an improvement to the documentation or
if you have noticed a small mistake (such as a spelling error or a typo),
it will be easier to send an email than to make a pull request. You will
be credited for the improvement unless you instruct Ceph Upstream
Documentation not to credit you.

Location of the Documentation in the Repository
===============================================

The Ceph documentation source is in the ``ceph/doc`` directory of the Ceph
repository. Python Sphinx renders the source into HTML and manpages. 

Viewing Old Ceph Documentation
==============================
The https://docs.ceph.com link displays the ``master`` branch by default, but
you can view the documentation for older versions of Ceph (e.g., ``mimic``) by
replacing the version name in the url (e.g. ``pacific`` in
`https://docs.ceph.com/en/pacific <https://docs.ceph.com/en/pacific>`_) with the
branch name you prefer (e.g. ``mimic``, to create a URL that reads
`https://docs.ceph.com/en/mimic/ <https://docs.ceph.com/en/mimic/>`_).

.. _making_contributions:

Making Contributions
====================

Making a documentation contribution involves the same basic procedure as making
a code contribution, with one exception: you must build documentation source
instead of compiling program source. This sequence (the sequence of building the documentation source) includes the following steps:

#. `Get the Source`_
#. `Select a Branch`_
#. `Make a Change`_
#. `Build the Source`_
#. `Commit the Change`_
#. `Push the Change`_
#. `Make a Pull Request`_
#. `Notify Us`_

Get the Source
--------------

Ceph documentation lives in the Ceph repository right alongside the Ceph source
code under the ``ceph/doc`` directory. For details on github and Ceph,
see :ref:`Get Involved`.

The most common way to make contributions is to use the `Fork and Pull`_
approach. You must:

#. Install git locally. For Debian/Ubuntu, execute:

   .. prompt:: bash $

	sudo apt-get install git

   For Fedora, execute:

   .. prompt:: bash $

	sudo yum install git

   For CentOS/RHEL, execute:

   .. prompt:: bash $

	sudo yum install git

#. Ensure your ``.gitconfig`` file has your name and email address. :

   .. code-block:: ini

	[user]
	   email = {your-email-address}
	   name = {your-name}

   For example:

   .. prompt:: bash $

	git config --global user.name "John Doe"
	git config --global user.email johndoe@example.com


#. Create a  `github`_ account (if you don't have one).

#. Fork the Ceph project. See https://github.com/ceph/ceph.

#. Clone your fork of the Ceph project to your local host.


Ceph organizes documentation into an information architecture primarily by its
main components.

- **Ceph Storage Cluster:** The Ceph Storage Cluster documentation resides
  under the ``doc/rados`` directory.
  
- **Ceph Block Device:** The Ceph Block Device documentation resides under
  the ``doc/rbd`` directory.
  
- **Ceph Object Storage:** The Ceph Object Storage documentation resides under
  the ``doc/radosgw`` directory.

- **Ceph File System:** The Ceph File System documentation resides under the 
  ``doc/cephfs`` directory.
  
- **Installation (Quick):** Quick start documentation resides under the
  ``doc/start`` directory.
  
- **Installation (Manual):** Manual installation documentation resides under
  the ``doc/install`` directory.
  
- **Manpage:** Manpage source resides under the ``doc/man`` directory.

- **Developer:** Developer documentation resides under the ``doc/dev`` 
  directory.

- **Images:** If you include images such as JPEG or PNG files, you should 
  store them under the ``doc/images`` directory.


Select a Branch
---------------

When you make small changes to the documentation, such as fixing typographical
errors or clarifying explanations, use the ``master`` branch (default). You
should also use the ``master`` branch when making contributions to features that
are in the current release. ``master`` is the most commonly used branch. :

.. prompt:: bash $

	git checkout master

When you make changes to documentation that affect an upcoming release, use 
the ``next`` branch. ``next`` is the second most commonly used branch. :

.. prompt:: bash $

	git checkout next

When you are making substantial contributions such as new features that are not
yet in the current release; if your contribution is related to an issue with a
tracker ID; or, if you want to see your documentation rendered on the Ceph.com
website before it gets merged into the ``master`` branch, you should create a
branch. To distinguish branches that include only documentation updates, we
prepend them with ``wip-doc`` by convention, following the form
``wip-doc-{your-branch-name}``. If the branch relates to an issue filed in
http://tracker.ceph.com/issues, the branch name incorporates the issue number.
For example, if a documentation branch is a fix for issue #4000, the branch name
should be ``wip-doc-4000`` by convention and the relevant tracker URL will be
http://tracker.ceph.com/issues/4000.

.. note:: Please do not mingle documentation contributions and source code
   contributions in a single commit. When you keep documentation
   commits separate from source code commits, it simplifies the review
   process. We highly recommend that any pull request that adds a feature or
   a configuration option, should also include a documentation commit,
   describing the relevant changes/options.

Before you create your branch name, ensure that it doesn't already exist in the
local or remote repository. :

.. prompt:: bash $

	git branch -a | grep wip-doc-{your-branch-name}

If it doesn't exist, create your branch:

.. prompt:: bash $

	git checkout -b wip-doc-{your-branch-name}


Make a Change
-------------

Modifying a document involves opening a reStructuredText file, changing
its contents, and saving the changes. See `Documentation Style Guide`_ for
details on syntax requirements.

Adding a document involves creating a new reStructuredText file within the
``doc`` directory tree with a ``*.rst``
extension. You must also include a reference to the document: a hyperlink
or a table of contents entry. The ``index.rst`` file of a top-level directory
usually contains a TOC, where you can add the new file name. All documents must
have a title. See `Headings`_ for details.

Your new document doesn't get tracked by ``git`` automatically. When you want 
to add the document to the repository,  you must use ``git add 
{path-to-filename}``. For example, from the top level  directory of the
repository, adding an ``example.rst`` file to the ``rados`` subdirectory would
look like this:

.. prompt:: bash $

	git add doc/rados/example.rst

Deleting a document involves removing it from the repository with ``git rm
{path-to-filename}``. For example:

.. prompt:: bash $

	git rm doc/rados/example.rst

You must also remove any reference to a deleted document from other documents.


Build the Source
----------------

To build the documentation, navigate to the ``ceph`` repository directory:


.. prompt:: bash $

	cd ceph

.. note::
   The directory that contains ``build-doc`` and ``serve-doc`` must be included
   in the ``PATH`` environment variable in order for these commands to work.


To build the documentation on Debian/Ubuntu, Fedora, or CentOS/RHEL, execute:

.. prompt:: bash $

	admin/build-doc

To scan for the reachability of external links, execute:

.. prompt:: bash $

	admin/build-doc linkcheck

Executing ``admin/build-doc`` will create a ``build-doc`` directory under
``ceph``.  You may need to create a directory under ``ceph/build-doc`` for
output of Javadoc files:

.. prompt:: bash $

	mkdir -p output/html/api/libcephfs-java/javadoc

The build script ``build-doc`` will produce an output of errors and warnings.
You MUST fix errors in documents you modified before committing a change, and
you SHOULD fix warnings that are related to syntax you modified.

.. important:: You must validate ALL HYPERLINKS. If a hyperlink is broken,
   it automatically breaks the build!

Once you build the documentation set, you may start an HTTP server at
``http://localhost:8080/`` to view it:

.. prompt:: bash $

	admin/serve-doc

You can also navigate to ``build-doc/output`` to inspect the built documents.
There should be an ``html`` directory and a ``man`` directory containing
documentation in HTML and manpage formats respectively.

Build the Source (First Time)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Ceph uses Python Sphinx, which is generally distribution agnostic. The first
time you build Ceph documentation, it will generate a doxygen XML tree, which
is a bit time consuming.

Python Sphinx does have some dependencies that vary across distributions. The
first time you build the documentation, the script will notify you if you do not
have the dependencies installed. To run Sphinx and build documentation successfully,
the following packages are required:

.. raw:: html

	<style type="text/css">div.body h3{margin:5px 0px 0px 0px;}</style>
	<table cellpadding="10"><colgroup><col width="30%"><col width="30%"><col width="30%"></colgroup><tbody valign="top"><tr><td><h3>Debian/Ubuntu</h3>

- gcc
- python3-dev
- python3-pip
- python3-sphinx
- python3-venv
- libxml2-dev
- libxslt1-dev
- doxygen
- graphviz
- ant
- ditaa

.. raw:: html

	</td><td><h3>Fedora</h3>

- gcc
- python-devel
- python-pip
- python-docutils
- python-jinja2
- python-pygments
- python-sphinx
- libxml2-devel
- libxslt1-devel
- doxygen
- graphviz
- ant
- ditaa

.. raw:: html

	</td><td><h3>CentOS/RHEL</h3>

- gcc
- python-devel
- python-pip
- python-docutils
- python-jinja2
- python-pygments
- python-sphinx
- libxml2-dev
- libxslt1-dev
- doxygen
- graphviz
- ant

.. raw:: html

	</td></tr></tbody></table>


Install each dependency that is not installed on your host. For Debian/Ubuntu
distributions, execute the following:

.. prompt:: bash $

	sudo apt-get install gcc python-dev python3-pip libxml2-dev libxslt-dev doxygen graphviz ant ditaa
	sudo apt-get install python-sphinx

For Fedora distributions, execute the following:

.. prompt:: bash $

   sudo yum install gcc python-devel python-pip libxml2-devel libxslt-devel doxygen graphviz ant
   sudo pip install html2text
   sudo yum install python-jinja2 python-pygments python-docutils python-sphinx
   sudo yum install jericho-html ditaa

For CentOS/RHEL distributions, it is recommended to have ``epel`` (Extra
Packages for Enterprise Linux) repository as it provides some extra packages
which are not available in the default repository. To install ``epel``, execute
the following:

.. prompt:: bash $

        sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

For CentOS/RHEL distributions, execute the following:

.. prompt:: bash $

	sudo yum install gcc python-devel python-pip libxml2-devel libxslt-devel doxygen graphviz ant
	sudo pip install html2text

For CentOS/RHEL distributions, the remaining python packages are not available
in the default and ``epel`` repositories. So, use http://rpmfind.net/ to find
the packages. Then, download them from a mirror and install them. For example:

.. prompt:: bash $

	wget http://rpmfind.net/linux/centos/7/os/x86_64/Packages/python-jinja2-2.7.2-2.el7.noarch.rpm
	sudo yum install python-jinja2-2.7.2-2.el7.noarch.rpm
	wget http://rpmfind.net/linux/centos/7/os/x86_64/Packages/python-pygments-1.4-9.el7.noarch.rpm
	sudo yum install python-pygments-1.4-9.el7.noarch.rpm
	wget http://rpmfind.net/linux/centos/7/os/x86_64/Packages/python-docutils-0.11-0.2.20130715svn7687.el7.noarch.rpm
	sudo yum install python-docutils-0.11-0.2.20130715svn7687.el7.noarch.rpm
	wget http://rpmfind.net/linux/centos/7/os/x86_64/Packages/python-sphinx-1.1.3-11.el7.noarch.rpm
	sudo yum install python-sphinx-1.1.3-11.el7.noarch.rpm

Ceph documentation makes extensive use of `ditaa`_, which is not presently built
for CentOS/RHEL7. You must install ``ditaa`` if you are making changes to
``ditaa`` diagrams so that you can verify that they render properly before you
commit new or modified ``ditaa`` diagrams. You may retrieve compatible required
packages for CentOS/RHEL distributions and install them manually. To run
``ditaa`` on CentOS/RHEL7, following dependencies are required:

- jericho-html
- jai-imageio-core
- batik

Use http://rpmfind.net/ to find compatible ``ditaa`` and the dependencies.
Then, download them from a mirror and install them. For example:

.. prompt:: bash $

	wget http://rpmfind.net/linux/fedora/linux/releases/22/Everything/x86_64/os/Packages/j/jericho-html-3.3-4.fc22.noarch.rpm
	sudo yum install jericho-html-3.3-4.fc22.noarch.rpm
	wget http://rpmfind.net/linux/centos/7/os/x86_64/Packages/jai-imageio-core-1.2-0.14.20100217cvs.el7.noarch.rpm
	sudo yum install jai-imageio-core-1.2-0.14.20100217cvs.el7.noarch.rpm
	wget http://rpmfind.net/linux/centos/7/os/x86_64/Packages/batik-1.8-0.12.svn1230816.el7.noarch.rpm
	sudo yum install batik-1.8-0.12.svn1230816.el7.noarch.rpm
	wget http://rpmfind.net/linux/fedora/linux/releases/22/Everything/x86_64/os/Packages/d/ditaa-0.9-13.r74.fc21.noarch.rpm
	sudo yum install ditaa-0.9-13.r74.fc21.noarch.rpm

Once you have installed all these packages, build the documentation by following
the steps given in `Build the Source`_.


Commit the Change
-----------------

Ceph documentation commits are simple, but follow a strict convention:

- A commit SHOULD have 1 file per commit (it simplifies rollback). You MAY
  commit multiple files with related changes. Unrelated changes SHOULD NOT
  be put into the same commit.
- A commit MUST have a comment.
- A commit comment MUST be prepended with ``doc:``. (strict)
- The comment summary MUST be one line only. (strict)
- Additional comments MAY follow a blank line after the summary, 
  but should be terse.
- A commit MAY include ``Fixes: https://tracker.ceph.com/issues/{bug number}``.
- Commits MUST include ``Signed-off-by: Firstname Lastname <email>``. (strict)

.. tip:: Follow the foregoing convention particularly where it says 
   ``(strict)`` or you will be asked to modify your commit to comply with 
   this convention.

The following is a common commit comment (preferred):: 

	doc: Fixes a spelling error and a broken hyperlink.
	
	Signed-off-by: John Doe <john.doe@gmail.com>


The following comment includes a reference to a bug. :: 

	doc: Fixes a spelling error and a broken hyperlink.

	Fixes: https://tracker.ceph.com/issues/1234
	
	Signed-off-by: John Doe <john.doe@gmail.com>


The following comment includes a terse sentence following the comment summary.
There is a carriage return between the summary line and the description:: 

	doc: Added mon setting to monitor config reference
	
	Describes 'mon setting', which is a new setting added
	to config_opts.h.
	
	Signed-off-by: John Doe <john.doe@gmail.com>


To commit changes, execute the following:

.. prompt:: bash $

	git commit -a
	

An easy way to manage your documentation commits is to use visual tools for
``git``. For example, ``gitk`` provides a graphical interface for viewing the
repository history, and ``git-gui`` provides a graphical interface for viewing
your uncommitted changes, staging them for commit, committing the changes and
pushing them to your forked Ceph repository.


For Debian/Ubuntu, execute:

.. prompt:: bash $

	sudo apt-get install gitk git-gui

For Fedora/CentOS/RHEL, execute:

.. prompt:: bash $

	sudo yum install gitk git-gui

Then, execute:

.. prompt:: bash $

	cd {git-ceph-repo-path}
	gitk
	
Finally, select **File->Start git gui** to activate the graphical user interface.


Push the Change
---------------

Once you have one or more commits, you must push them from the local copy of the
repository to ``github``. A graphical tool like ``git-gui`` provides a user
interface for pushing to the repository. If you created a branch previously:

.. prompt:: bash $

	git push origin wip-doc-{your-branch-name}

Otherwise:

.. prompt:: bash $

	git push


Make a Pull Request
-------------------

As noted earlier, you can make documentation contributions using the `Fork and
Pull`_ approach.



Notify Us
---------

In case The PR did not got a review within in a reasonable timeframe, please get in touch
with the corresponding component lead of the :ref:`clt`.

Documentation Style Guide
=========================

One objective of the Ceph documentation project is to ensure the readability of
the documentation in both native reStructuredText format and its rendered
formats such as HTML. Navigate to your Ceph repository and view a document in
its native format. You may notice that it is generally as legible in a terminal
as it is in its rendered HTML format. Additionally, you may also notice that
diagrams in ``ditaa`` format also render reasonably well in text mode. :

.. prompt:: bash $

	less doc/architecture.rst

Review the following style guides to maintain this consistency.


Headings
--------

#. **Document Titles:** Document titles use the ``=`` character overline and 
   underline with a leading and trailing space on the title text line. 
   See `Document Title`_ for details.

#. **Section Titles:** Section tiles use the ``=`` character underline with no
   leading or trailing spaces for text. Two carriage returns should precede a 
   section title (unless an inline reference precedes it). See `Sections`_ for
   details.

#. **Subsection Titles:** Subsection titles use the ``_`` character underline 
   with no leading or trailing spaces for text.  Two carriage returns should 
   precede a subsection title (unless an inline reference precedes it).


Text Body
---------

As a general rule, we prefer text to wrap at column 80 so that it is legible in
a command line interface without leading or trailing white space. Where
possible, we prefer to maintain this convention with text, lists, literal text
(exceptions allowed), tables, and ``ditaa`` graphics.

#. **Paragraphs**: Paragraphs have a leading and a trailing carriage return, 
   and should be 80 characters wide or less so that the documentation can be 
   read in native format in a command line terminal.

#. **Literal Text:** To create an example of literal text (e.g., command line
   usage), terminate the preceding paragraph with ``::`` or enter a carriage
   return to create an empty line after the preceding paragraph; then, enter
   ``::`` on a separate line followed by another empty line. Then, begin the
   literal text with tab indentation (preferred) or space indentation of 3 
   characters.

#. **Indented Text:** Indented text such as bullet points 
   (e.g., ``- some text``) may span multiple lines. The text of subsequent
   lines should begin at the same character position as the text of the
   indented text (less numbers, bullets, etc.).

   Indented text may include literal text examples. Whereas, text indentation
   should be done with spaces, literal text examples should be indented with
   tabs. This convention enables you to add an additional indented paragraph
   following a literal example by leaving a blank line and beginning the
   subsequent paragraph with space indentation.

#. **Numbered Lists:** Numbered lists should use autonumbering by starting
   a numbered indent with ``#.`` instead of the actual number so that
   numbered paragraphs can be repositioned without requiring manual 
   renumbering.

#. **Code Examples:** Ceph supports the use of the 
   ``.. code-block::<language>`` role, so that you can add highlighting to 
   source examples. This is preferred for source code. However, use of this 
   tag will cause autonumbering to restart at 1 if it is used as an example 
   within a numbered list. See `Showing code examples`_ for details.


Paragraph Level Markup
----------------------

The Ceph project uses `paragraph level markup`_ to highlight points.

#. **Tip:** Use the ``.. tip::`` directive to provide additional information
   that assists the reader or steers the reader away from trouble.

#. **Note**: Use the ``.. note::`` directive to highlight an important point.

#. **Important:** Use the ``.. important::`` directive to highlight important
   requirements or caveats (e.g., anything that could lead to data loss). Use
   this directive sparingly, because it renders in red.

#. **Version Added:** Use the ``.. versionadded::`` directive for new features
   or configuration settings so that users know the minimum release for using
   a feature.
   
#. **Version Changed:** Use the ``.. versionchanged::`` directive for changes
   in usage or configuration settings.

#. **Deprecated:** Use the ``.. deprecated::`` directive when CLI usage, 
   a feature or a configuration setting is no longer preferred or will be 
   discontinued.

#. **Topic:** Use the ``.. topic::`` directive to encapsulate text that is
   outside the main flow of the document. See the `topic directive`_ for
   additional details.


TOC and Hyperlinks
------------------

All documents must be linked from another document or a table of contents,
otherwise you will receive a warning when building the documentation.

The Ceph project uses the ``.. toctree::`` directive. See `The TOC tree`_
for details. When rendering a TOC, consider specifying the ``:maxdepth:`` 
parameter so the rendered TOC is reasonably terse.

Document authors should prefer to use the ``:ref:`` syntax where a link target
contains a specific unique identifier (e.g., ``.. _unique-target-id:``), and  a
reference to the target specifically references the target  (e.g.,
``:ref:`unique-target-id```) so that if source files are moved or the
information architecture changes, the links will still work. See
`Cross referencing arbitrary locations`_ for details.

Ceph documentation also uses the backtick (accent grave) character followed by
the link text, another backtick and an underscore. Sphinx allows you to
incorporate the link destination inline; however, we prefer to use the use the
``.. _Link Text: ../path`` convention at the bottom of the document, because it
improves the readability of the document in a command line interface.


.. _Python Sphinx: http://sphinx-doc.org
.. _resturcturedText: http://docutils.sourceforge.net/rst.html
.. _Fork and Pull: https://help.github.com/articles/using-pull-requests
.. _github: http://github.com
.. _ditaa: http://ditaa.sourceforge.net/
.. _Document Title: http://docutils.sourceforge.net/docs/user/rst/quickstart.html#document-title-subtitle
.. _Sections: http://docutils.sourceforge.net/docs/user/rst/quickstart.html#sections
.. _Cross referencing arbitrary locations: http://www.sphinx-doc.org/en/master/usage/restructuredtext/roles.html#role-ref
.. _The TOC tree: http://sphinx-doc.org/markup/toctree.html
.. _Showing code examples: http://sphinx-doc.org/markup/code.html
.. _paragraph level markup: http://sphinx-doc.org/markup/para.html
.. _topic directive: http://docutils.sourceforge.net/docs/ref/rst/directives.html#topic
