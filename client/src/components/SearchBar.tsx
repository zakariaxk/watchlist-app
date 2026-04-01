import '../styles/searchbar.css';
import { useState, useEffect } from 'react';

interface SearchBarProps {
  onSearch: (query: string) => void;
}

const MIN_CHARS = 3;
const DEBOUNCE_MS = 500;

const SearchBar = ({ onSearch }: SearchBarProps) => {
  const [value, setValue] = useState('');

  useEffect(() => {
    if (value.length === 0) {
      onSearch('');
      return;
    }
    if (value.length < MIN_CHARS) return;

    const timer = setTimeout(() => {
      onSearch(value);
    }, DEBOUNCE_MS);

    return () => clearTimeout(timer);
  }, [value]);

  return (
    <div className="search-bar">
      <input
        type="text"
        placeholder="Search movies or TV shows..."
        value={value}
        onChange={(e) => setValue(e.target.value)}
        className="search-input"
      />
      {value.length > 0 && value.length < MIN_CHARS && (
        <p className="search-hint">Type at least {MIN_CHARS} characters to search.</p>
      )}
    </div>
  );
};

export default SearchBar;
