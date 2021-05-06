#!/usr/bin/env ruby

require "rbscmlex"

def parse_program(lex)
  program = []
  loop {
    program << parse_expression(lex)
  }
  program
end

def parse_expression(lex)
  if lex.peek_token.type == :lparen
    parse_list(lex)
  else
    parse_simple(lex)
  end
end

def parse_list(lex)
  lex.next_token                # skip :lparen
  list = []
  loop {
    break if lex.peek_token.type == :rparen
    list << parse_expression(lex)
  }
  lex.next_token                # skip :rparen
  list
end

def parse_simple(lex)
  lex.next_token.literal
end

source = ARGF.entries.join(" ")
lex = Rbscmlex::Lexer.new(source)

result = parse_program(lex)

pp result
