package com.shopizer.catalog.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Basic Spring Security configuration.
 *
 * Current policy (initial scaffold):
 * - Public: Swagger UI + OpenAPI docs, Actuator health, and GET product browsing endpoint(s).
 * - Protected: everything else (future admin/write APIs).
 *
 * Auth mechanism is intentionally minimal at this step (HTTP Basic) until platform-wide identity service is defined.
 */
@Configuration
public class SecurityConfig {

  // PUBLIC_INTERFACE
  @Bean
  public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    /** Defines the service HTTP security filter chain. */
    http
        // This service will evolve to token-based auth; keep it stateless by default.
        .csrf(csrf -> csrf.disable())
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/swagger-ui/**", "/v3/api-docs/**", "/openapi.json").permitAll()
            .requestMatchers("/actuator/health/**", "/actuator/info").permitAll()
            .requestMatchers(HttpMethod.GET, "/api/v1/catalog/products/**").permitAll()
            .anyRequest().authenticated()
        )
        .httpBasic(Customizer.withDefaults());

    return http.build();
  }
}
