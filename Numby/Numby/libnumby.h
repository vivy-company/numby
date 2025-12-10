#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

/**
 * Agent priority constants. Lower priority values run first.
 * The order is designed to process high-specificity agents before fallback math evaluation.
 */
#define PRIORITY_HISTORY 10

#define PRIORITY_VARIABLE 20

#define PRIORITY_PERCENTAGE 30

#define PRIORITY_UNIT 40

#define PRIORITY_MATH 50

/**
 * Validate input size limits
 */
#define MAX_EXPR_LENGTH 100000

typedef struct AppState AppState;

typedef struct AppState NumbyContext;

NumbyContext *libnumby_context_new(void);

double libnumby_evaluate(NumbyContext *ctx,
                         const char *input,
                         char **out_formatted,
                         char **out_unit,
                         char **out_error);

int32_t libnumby_set_variable(NumbyContext *ctx, const char *name, double value, const char *unit);

int32_t libnumby_load_config(NumbyContext *ctx, const char *path);

int32_t libnumby_set_locale(NumbyContext *ctx, const char *locale);

/**
 * Gets the current locale
 * Caller must free the returned string with libnumby_free_string
 */
char *libnumby_get_locale(void);

/**
 * Gets the number of available locales
 */
int32_t libnumby_get_locales_count(void);

/**
 * Gets the locale code at the specified index
 * Caller must free the returned string with libnumby_free_string
 */
char *libnumby_get_locale_code(int32_t index);

/**
 * Gets the locale display name at the specified index
 * Caller must free the returned string with libnumby_free_string
 */
char *libnumby_get_locale_name(int32_t index);

void libnumby_free_string(char *s);

int32_t libnumby_clear_history(NumbyContext *ctx);

/**
 * Clear all variables from the context
 */
int32_t libnumby_clear_variables(NumbyContext *ctx);

int32_t libnumby_get_history_count(NumbyContext *ctx);

void libnumby_context_free(NumbyContext *ctx);

/**
 * Returns the default configuration path that the Rust core uses.
 * Caller must free the returned string with libnumby_free_string.
 */
char *libnumby_get_default_config_path(void);

/**
 * Fetches latest currency rates from the API and updates the config file
 *
 * Returns 0 on success, -1 on failure
 * On success, updates both the config file and the context's rates
 *
 * Note: This uses Rust's ureq for HTTP requests which may not work on all platforms
 * (e.g., visionOS). Use libnumby_set_currency_rates_json for platform-native HTTP.
 */
int32_t libnumby_update_currency_rates(NumbyContext *ctx);

/**
 * Sets currency rates from JSON data provided by the caller
 *
 * Expected JSON format: {"date": "2025-01-01", "usd": {"eur": 0.92, "gbp": 0.79, ...}}
 * This allows using platform-native HTTP (e.g., Swift URLSession) to fetch rates.
 *
 * Returns 0 on success, -1 on failure
 */
int32_t libnumby_set_currency_rates_json(NumbyContext *ctx, const char *json_data);

/**
 * Checks if currency rates are stale (older than 24 hours)
 *
 * Returns 1 if stale, 0 if fresh, -1 on error
 */
int32_t libnumby_are_rates_stale(void);

/**
 * Gets the last update date for currency rates
 *
 * Returns a C string with the date in YYYY-MM-DD format, or null if unavailable
 * Caller must free the returned string with libnumby_free_string
 */
char *libnumby_get_rates_update_date(void);
