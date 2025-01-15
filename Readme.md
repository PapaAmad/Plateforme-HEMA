# Projet de statistique exploratoire spatiale

# Important Notice (as of 2024-06-18)

> **Important**  
> Due to all the new major changes coming to Leon AI, the development branch might be unstable.  
> It is recommended to use the older version under the master branch.

Please note that older versions do not make use of any foundation model, which will be introduced in upcoming versions.

---

## Outdated Documentation

Please note that the documentation and this README are not up to date. We’ve made significant changes to Leon over the past few months, including the introduction of new TTS and ASR engines, and a hybrid approach that balances LLM, simple classification, and multiple NLP techniques to achieve optimal speed, customization, and accuracy. We’ll update the documentation for the official release.

---

## Project History and Future Plans

Since its inception in 2017, Leon has undergone significant transformations. Although we’ve been inconsistent in shipping updates over the years, we’re now focused on maturing the project. With the recent integration of transformers-based models, we’re prepared to unlock Leon’s full potential.

Our next step is to finalize the latest features for the official release. Then we’ll be establishing a group of active contributors to work together, develop new skills, and share them with the community. A skill registry platform will be built (see it as the npm or pip registry but for skills).

While I would love to devote more time to Leon, I’m currently unable to do so because I have bills to pay. I have some ideas about how to monetize Leon in the future (Leon’s core will always remain open source), but before getting there, there is still a long way to go.

Until then, any financial support by [sponsoring Leon](#) is much appreciated 🙂

---

## Latest Release

Check out the [latest release blog post](#).

![Leon v8-beta](https://user-images.githubusercontent.com/placeholder/demo.png)

- **No Python Env at Runtime**
- **TypeScript Rewrite**
- **New Codebase**
- **Telemetry Service**
- **Report Service & More!**

---

## Introduction

Leon is an open-source personal assistant who can live on your server.

### Why?

1. If you are a developer (or not), you may want to build many things that could help in your daily life.  
   Instead of building a dedicated project for each of those ideas, Leon can help you with his Skills structure.

2. With this generic structure, everyone can create their own skills and share them with others.  
   Therefore there is only one core (to rule them all).

3. Leon uses AI concepts, which is cool.

4. Privacy matters; you can configure Leon to talk with him offline.  
   You can already text with him without any third-party services.

5. Open source is great.

---

## What is this repository for?

This repository contains the following nodes of Leon:

- **The server**  
- **Skills**  
- **The web app**  
- **The hotword node**  
- **The TCP server** (for inter-process communication between Leon and third-party nodes such as spaCy)  
- **The Python bridge** (the connector between the core and skills made with Python)

---

## What is Leon able to do?

- Perform voice commands (STT/TTS)
- Support text-based interactions
- Handle various “skills” for different tasks
- Let you create and share new skills

*(More functionalities will be documented soon...)*

---

## Prerequisites

Make sure you have the following installed:

- **Node.js** (version X or above)
- **npm** or **yarn**
- **Python** (version 3.XX)

To install these prerequisites, you can follow the [How To](#) section of the documentation.

---

## Installation

```bash
# Install the Leon CLI
npm install --global @leon-ai/cli

# Install Leon (stable branch)
leon create birth

# OR install from the develop branch:
leon create birth --develop
