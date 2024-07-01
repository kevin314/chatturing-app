# Use the official Elixir image with specific versions for Elixir and OTP
FROM elixir:1.16.3-otp-26

# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# If you need Node.js for asset compilation
# RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
#     apt-get install -y nodejs

# Set the working directory
WORKDIR /app

# Copy the mix.exs and mix.lock files to the container
COPY mix.exs mix.lock ./

# Install Elixir dependencies
RUN mix deps.get

# Copy the rest of the application code to the container
COPY . .

# If you have assets and need to compile them
# RUN npm install --prefix ./assets
# RUN npm run deploy --prefix ./assets
# RUN mix phx.digest

# Compile the Elixir/Phoenix application
RUN mix compile

# Expose the port that the Phoenix server will run on
EXPOSE 4000

# Set the entry point to run the Phoenix server
CMD ["mix", "phx.server"]