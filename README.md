# Ubunut-based Wekan Docker Image

[Wekan](https://github.com/wekan/wekan) is an completely Open Source and Free software collaborative kanban board application with MIT license.

Whether you’re maintaining a personal todo list, planning your holidays with some friends, or working in a team on your next revolutionary idea, Kanban boards are an unbeatable tool to keep your things organized. They give you a visual overview of the current state of your project, and make you productive by allowing you to focus on the few items that matter the most.

## Why another container?

I totally love Wekan, but I'm really sorry to admid that the default docker-file simply sucks!

This Dockerfile is based on the original one, but does not cramp all commands into a single RUN statement. Forthermore it switches to a low-priv user at the end so node does not run as root (like in the original image). 