{...}: {
  age.secrets = {
    openai.file = ./openai.age;
    anthropic.file = ./anthropic.age;
  };
}
