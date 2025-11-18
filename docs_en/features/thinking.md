---
sidebar_position: 2
hide_title: true
---

# Thinking Capability

> **Feature Overview**: Thinking Capability is iFlow CLI's intelligent reasoning system that triggers AI deep thinking through keywords, providing deeper analysis and reasoning.
>
> **Learning Time**: 10-15 minutes
>
> **Prerequisites**: iFlow CLI installed and configured, basic command line operations

## What is Thinking Capability

Thinking Capability is iFlow CLI's built-in intelligent reasoning enhancement system that triggers AI model's deep thinking mode by recognizing specific keywords in user input. When activated, the AI will perform internal reasoning before giving final answers, showing its thought process to provide more accurate and deeper responses.

## Core Features

| Feature | Description | Advantage |
|---------|-------------|-----------|
| Smart Keyword Recognition | Supports English thinking trigger words | Natural language interaction |
| Multi-level Reasoning Intensity | 5 reasoning levels: none, normal, hard, mega, ultra | Precise thinking depth control |
| Real-time Thinking Display | Shows AI's thinking process | Enhanced transparency and credibility |
| Multi-model Adaptation | Supports OpenAI o1, DeepSeek, GLM-4.5, etc. | Broad model compatibility |
| Flexible Display Modes | Full, compact, indicator display modes | Adapts to different usage scenarios |

## How It Works

### Thinking Trigger Flow

```
User Input → Keyword Analysis → Intent Recognition → Config Generation → Model Call → Thinking Display
    ↓
[Contains thinking words] → [Regex matching] → [Reasoning level] → [Token limit] → [Deep reasoning] → [Process visualization]
```

### Reasoning Level System

- **none**: No thinking mode, direct response (0 tokens)
- **normal**: Basic thinking, recognizes "think" and other basic words (2,000 tokens)
- **hard**: Intermediate thinking, recognizes "think harder" and other words (4,000 tokens)
- **mega**: Advanced thinking, recognizes "think really hard" and other words (10,000 tokens)
- **ultra**: Super thinking, recognizes "think super hard" and other words (32,000 tokens)

## Detailed Feature Description

### Keyword Trigger System

#### English Trigger Words

**Super Thinking (Ultra)**:
- `ultrathink`
- `think really super hard`
- `think intensely`

**Mega Thinking (Mega)**:
- `megathink`
- `think really hard`
- `think a lot`

**Hard Thinking (Hard)**:
- `think about it`
- `think more`
- `think harder`

**Basic Thinking (Normal)**:
- `think`

### Thinking Display

The thinking process is presented in the thinking status indicator.

```
✻ Thinking...
```

### Model Adaptation System

Thinking capability currently supports hybrid reasoning models and currently supports the **glm-4.5** model.

## Usage Examples

### Basic Usage

```bash

# 
> Think deeply about this complex system design problem
```

### English Usage

```bash
# Super thinking
> ultrathink this complex system design
```

## Best Practices

### Troubleshooting

#### Thinking Not Triggered
- Check if input contains correct trigger keywords
- Verify if the model being used supports thinking capability
- Confirm environment variable configuration is correct

## Comparison with Related Features

### Thinking Capability vs. Normal Conversation

Thinking capability performs internal reasoning before answering, while normal conversation generates answers directly. Thinking mode provides deeper analysis but consumes more computational resources.

### Thinking Capability vs. SubAgent

Thinking capability is a single model's internal reasoning process, while SubAgent calls specialized agents to handle specific tasks. Thinking capability focuses on reasoning depth, SubAgent focuses on task specialization.